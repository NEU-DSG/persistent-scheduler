xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace sched="http://exist-db.org/xquery/scheduler";
import module namespace util="http://exist-db.org/xquery/util";
(: NAMESPACES :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : 
 :)
 
(: VARIABLES :)
  declare variable $jobs := map { 
    'Test job': map {
      'xq': '/db/test/test-job.xq',
      'cron': '0 0/5 * 1/1 * ? *',
      'parameters': ()
      }
    };
  
(: FUNCTIONS :)

(: MAIN QUERY :)

let $scheduling :=
  for $job-name in map:keys($jobs)
  let $job := $jobs($job-name)
  return sched:schedule-xquery-cron-job(
          $job?xq,
          $job?cron,
          $job-name,
          $job?parameters
          )
return
  util:log-system-out(sm:id())

