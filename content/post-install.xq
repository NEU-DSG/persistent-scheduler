xquery version "3.0";

(:  LIBRARIES  :)
  import module namespace console="http://exist-db.org/xquery/console";
  import module namespace sm="http://exist-db.org/xquery/securitymanager";

(:~ 
  This script will be run after the package is installed into eXist DB.
:)
 
(:  VARIABLES  :)
(: The following external variables are set by repo:deploy(). :)
  (: File path pointing to the eXist installation directory. :)
  declare variable $home external;
  (: Path to the directory containing the unpacked .xar package. :)
  declare variable $dir external;
  (: The target collection into which the app is deployed. :)
  declare variable $target external;
  
  declare variable $target-full := 'xmldb:exist://'||$target||'/';


(:  MAIN QUERY  :)

(:
  Apply special permissions to some files:
    * rescheduler.xq may be configured to execute when eXist restarts, and so it must 
      be executable by the guest user. Setgid allows even the guest user to run 
      imported code which would otherwise be locked to the dba group.
    * content/scheduler.xql is the library that manages scheduling. For security, it 
      is usable only by users in the dba group. Access is otherwise granted by 
      applying setgid to an XQuery owned by the dba group.
    * data/activity-log.xml and data/catalog.xml describe scheduled XQuery jobs. For
      security, these files are not readable outside of the dba group. Instead, they
      can be accessed indirectly through the aforementioned setgid method.
:)
let $specialPermissions := map {
    $target-full||'rescheduler.xq' :
      'rwxrwsr-x',
    $target-full||'content/scheduler.xql' :
      'rwxr-xr--',
    $target-full||'data/activity-log.xml' :
      'rw-rw----',
    $target-full||'data/catalog.xml' :
      'rw-rw----'
  }
return 
  for $file in map:keys($specialPermissions)
  let $perm := $specialPermissions($file)
  return
    sm:chmod(xs:anyURI($file), $perm)

