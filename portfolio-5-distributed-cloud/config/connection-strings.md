# Connection strings for the proposed design

Application writes (dispatch service recording trip events):

    mongodb://mongo-a:27017,mongo-b:27017,mongo-c:27017/ridehailing?replicaSet=rh-events&w=majority&retryWrites=true

Analyst reads (can tolerate a few seconds of lag, keeps load off the primary):

    mongodb://mongo-a:27017,mongo-b:27017,mongo-c:27017/ridehailing?replicaSet=rh-events&readPreference=secondaryPreferred&maxStalenessSeconds=90&readConcernLevel=majority

`maxStalenessSeconds` must be at least 90 in MongoDB; a secondary that falls further behind than that is skipped.
