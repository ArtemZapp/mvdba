/*
  SCRIPT:   SES_EVENTS.SQL
  OBJETIVO: EVENTOS POR SESSAO
  AUTOR:    JOSIVAN
  DATA:     2000.02.08   
*/
COLUMN OSUSER FORMAT A12
COLUMN EVENT FORMAT A30
--
  SELECT S.OSUSER
        ,SE.EVENT
        ,SE.TOTAL_WAITS
        ,SE.TOTAL_TIMEOUTS
        ,SE.TIME_WAITED
        ,SE.AVERAGE_WAIT
        ,SE.MAX_WAIT
    FROM V$SESSION_EVENT SE
        ,V$SESSION S
   WHERE SE.SID   = S.SID
     AND S.STATUS = 'ACTIVE'
     AND S.OSUSER <> 'oracle'
ORDER BY 1
/
