import json
import random
import time

from functools import wraps

class Continuation(Exception): pass
class Sleep(Exception): pass

def with_continuation(fn):
    @wraps(fn)
    def handler(event, context):
        if "continuation" in event:
            cause = json.loads(event["continuation"]["Cause"])
            cont = json.loads(cause["errorMessage"])
            del event["continuation"]
        else:
            cont = None
        
        try:
            return fn(event, cont, context)
        except Continuation as ex:
            if len(ex.args) == 0:
                ex.args = ["true"]
            elif len(ex.args) == 1:
                ex.args = [json.dumps(ex.args[0])]
            elif len(ex.args) > 1:
                ex.args = [json.dumps(list(ex.args))]
            raise ex

    return handler
