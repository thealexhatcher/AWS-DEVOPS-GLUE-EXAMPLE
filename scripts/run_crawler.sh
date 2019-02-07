#!/bin/bash
CRAWLER=$(./cfn.py output --stack-name $DATALAKE_STACKNAME --output ProcessedCrawler)

time {
    echo "Starting crawler '$CRAWLER'"
    aws glue start-crawler --name $CRAWLER
    
    echo "waiting for crawl to finish"
    while true; do
        state=$(aws glue get-crawler --name $CRAWLER --query 'Crawler.State' --output text)
        if [ "$state" = "READY" ]; then
            break
        fi
        sleep 60
    done
}

aws glue get-crawler --name $CRAWLER --query 'Crawler.LastCrawl' --output table
aws glue get-crawler-metrics --query "CrawlerMetricsList[?CrawlerName=='$CRAWLER']" --output table