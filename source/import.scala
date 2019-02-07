import com.amazonaws.services.glue.DynamicRecord
import com.amazonaws.services.glue.GlueContext
import com.amazonaws.services.glue.util.GlueArgParser
import com.amazonaws.services.glue.util.Job
import com.amazonaws.services.glue.types._
import org.apache.spark.SparkContext
import org.apache.hadoop.io.Text;
import org.apache.hadoop.dynamodb.DynamoDBItemWritable
import com.amazonaws.services.dynamodbv2.model.AttributeValue
import org.apache.hadoop.dynamodb.read.DynamoDBInputFormat
import org.apache.hadoop.dynamodb.write.DynamoDBOutputFormat
import org.apache.hadoop.mapred.JobConf
import org.apache.hadoop.io.LongWritable
import java.util.HashMap
import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import scala.collection.JavaConversions

object GlueJob extends java.io.Serializable {
  def main(sysArgs: Array[String]): Unit = {
    val sc: SparkContext = SparkContext.getOrCreate()
    val gc: GlueContext = new GlueContext(sc)
    val required = Array(
      "glueDatabase",
      "ddbTableName",
      "region",
      "partitionCode",
      "cycleDate")
    
    val args = GlueArgParser.getResolvedOptions(sysArgs, required)
    val database = args("glueDatabase")
    val tableName = args("ddbTableName")
    val region = args("region")
    val partitionCode = args("partitionCode")
    val cycleDate = args("cycleDate")
    
    val acct_summary = 
      getDataFrame(gc, database, "account_summary_dc", partitionCode, cycleDate)
        .withColumn("business_unit", col("partition_code"))
        .drop("partition_code", "cycle_date")
        .withColumn("sort_key", col("account_id"))
        .withColumn("type", lit("summary#account"))
        
    val person_summary = 
      getDataFrame(gc, database, "person_summary_dc", partitionCode, cycleDate)
        .withColumn("sort_key", col("person_id").cast(StringType))
        .drop("partition_code", "cycle_date")
        .withColumn("type", lit("summary#person"))
        
    writeToDynamoDB(sc, acct_summary, tableName, region)
    writeToDynamoDB(sc, person_summary, tableName, region)
  }
  
  def getDataFrame(gc:GlueContext, database:String, table:String, partition_code:String, cycle_date:String) : DataFrame = {
    val pred = s"partition_code='$partition_code' AND cycle_date='$cycle_date'"
    gc.getCatalogSource(database=database, tableName=table, pushDownPredicate=pred)
      .getDynamicFrame()
      .toDF()
  }

  def writeToDynamoDB(sc:SparkContext, dataframe:DataFrame, tableName:String, region:String) = {
    val conf = new JobConf(sc.hadoopConfiguration)  {
      set("dynamodb.output.tableName", tableName)
      set("dynamodb.regionid", region)
      set("dynamodb.throughput.write.percent", "1.0")
      set("mapred.output.format.class", "org.apache.hadoop.dynamodb.write.DynamoDBOutputFormat")
      set("mapred.output.committer.class", "org.apache.hadoop.mapred.FileOutputCommitter")
    }
    dataframe
      .drop("partition_code", "cycle_date")
      .rdd.map(row => {
        val item = new DynamoDBItemWritable()
        item.setItem(rowToAttrMap(row))
        (new Text(""), item) })
      .saveAsHadoopDataset(conf)
  }
  
  def rowToAttrMap(row:Row) : HashMap[String, AttributeValue] = {
    val hm = new HashMap[String, AttributeValue]()
    
    for ((field, i) <- row.schema.fields.zipWithIndex) {
      var attr = new AttributeValue()
      
      if (!row.isNullAt(i)) {
        val value = row.get(i)
        field.dataType match {
          // assume ArrayType is a list of struct Struct Fields
          case ArrayType(StructType(_),_) => 
          {
            val arr = row.getAs[Seq[Row]](i).map((row) => 
            {
              val elem = new AttributeValue()
              elem.setM(rowToAttrMap(row))
              elem 
            })
            attr.setL(JavaConversions.asJavaCollection(arr))
          }
          case StructType(_) => attr.setM(rowToAttrMap(value.asInstanceOf[Row]))
          // set booleans as boolean
          case BooleanType    => attr.setBOOL(value.asInstanceOf[Boolean].booleanValue)
          // set numbers as numeric types
          case IntegerType    => attr.setN(value.toString)
          case DecimalType()  => attr.setN(value.toString)
          case DoubleType     => attr.setN(value.toString)
          case FloatType      => attr.setN(value.toString)
          case LongType       => attr.setN(value.toString)
          case ShortType      => attr.setN(value.toString)
          // everything else, assume it is a string
          case _ => attr.setS(value.toString)
        }
      } else {
        attr.setNULL(true)
      }
      hm.put(field.name, attr)
    }
    
    return hm
  }
}
