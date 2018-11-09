xquery version "3.0";

  import module namespace pjs="http://www.wwp.northeastern.edu/ns/persistent-scheduler" 
    at "content/scheduler.xql";
(:  NAMESPACES  :)
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(:~
  Reschedule any catalogued persistent jobs.
  
  This module is intended to be used programmatically. To enable this, add the user job below to 
  EXIST_HOME/conf.xml, inside `/exist/scheduler`:
      <job type="user" name="persistent-scheduler" 
        xquery="/db/apps/persistent-scheduler/test-scheduler.xq"
        period="5000" repeat="0" />
  By adding a reference to this XQuery to conf.xml, the XQuery jobs will be rescheduled immediately 
  after eXist DB starts back up.
  
  *Note:* While the Persistent Scheduler has safeguards built in, you should only add this script to
  your eXist DB configuration if you have confidence that only trusted users can register a scheduled
  job.
  
  If you can't (or prefer not to risk) rescheduling jobs programmatically, you should still be able to 
  run this script yourself after restarting eXist and examining the contents of the job catalog.
:)
 

(:  MAIN QUERY  :)

pjs:reschedule-xquery-jobs()
