xquery version "3.0";

  (:declare boundary-space preserve;:)
(:  LIBRARIES  :)
  import module namespace pjs="http://www.wwp.northeastern.edu/ns/persistent-scheduler";
(:  NAMESPACES  :)
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare option output:media-type "text/html";
  declare option output:method "xhtml";

(:~
  
 :)
 
(:  VARIABLES  :)
  declare variable $datapath := "../data/";

(:  FUNCTIONS  :)
  

(:  MAIN QUERY  :)

let $registeredQueries := 
  let $filepath := concat($datapath, 'catalog.xml')
  return doc($filepath)/jobs/job
let $logEntries :=
  let $filepath := concat($datapath, 'activity-log.xml')
  return doc($filepath)/log/entry
return
  <html>
    <head>
      <title>Persistent Scheduler</title>
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <style><![CDATA[
        body { 
          padding: 1.5em 1em 1em;
          font-family: Verdana, Geneva, sans-serif;
        }
      ]]></style>
    </head>
    <body>
      <h1>Persistent Scheduler</h1>
      <p>Jobs: { count($registeredQueries) }</p>
      <p>Log entries: { count($logEntries) }</p>
    </body>
  </html>
