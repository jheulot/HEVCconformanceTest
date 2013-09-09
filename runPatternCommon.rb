###############################################################################
# Constant
###############################################################################
OPEN_HEVC_IDX   = 1
AVCONV_IDX      = 2
HM_IDX          = 3
###############################################################################
# Global
###############################################################################
#
$appli          = []
#
$appli[OPEN_HEVC_IDX]             = {}
$appli[OPEN_HEVC_IDX]["option"]   = "-n -p 3 -i"
$appli[OPEN_HEVC_IDX]["output"]   = ""
$appli[OPEN_HEVC_IDX]["label"]    = "openHEVC"
#
#
$appli[AVCONV_IDX]                = {}
$appli[AVCONV_IDX]["option"]      = "-decode-checksum 1  -threads 3 -i"
$appli[AVCONV_IDX]["output"]      = "-f null -"
$appli[AVCONV_IDX]["label"]       = "avconv"
#
$appli[HM_IDX]                    = {}
$appli[HM_IDX]["option"]          = "-b"
$appli[HM_IDX]["output"]          = ""
$appli[HM_IDX]["label"]           = "HM"
#
###############################################################################
# getopts
###############################################################################
def getopts (argv)
  help() if argv.size == 0
  $sourcePattern = nil
  $exec          = nil
  $stop          = true
  for i in (0..argv.size) do
    case argv[i]
    when "-h"         : help();
    when "-dir"       : $sourcePattern = argv[i+1]
    when "-exec"      : $exec          = argv[i+1]
    when "-noStop"    : $stop          = false
    end
  end
  help() if $sourcePattern == nil or $exec == nil
  $appliIdx = if /hevc/ =~ $exec then OPEN_HEVC_IDX elsif /TAppDecoder/ =~ $exec then HM_IDX else AVCONV_IDX end
end
###############################################################################
# help
###############################################################################
def help ()
  puts "======================================================================"
  puts "== runPattern options :                                             =="
  puts "==             -h         : help                                    =="
  puts "==             -dir       : pattern directory path                  =="
  puts "==             -exec      : exec path                               =="
  puts "==             -noStop    : not stop when diff is not ok            =="
  puts "======================================================================"
  exit
end
###############################################################################
# getListFile
###############################################################################
def getListFile ()
  if File.exists?($sourcePattern) then
    pwd   = Dir.pwd
    Dir.chdir($sourcePattern)
    list  = Dir.glob("*.bin")
    list += Dir.glob("*.bit")
    Dir.chdir(pwd)
    return list.sort
  end
  return []
end
###############################################################################
# getMaxSizeFileName
###############################################################################
def getMaxSizeFileName (listFile)
  maxSize = 0
  listFile.each do |binFile|
    maxSize = binFile.size if binFile.size > maxSize
  end
  return maxSize
end
###############################################################################
# save_md5
###############################################################################
def save_md5(md5) 
  if $appliIdx == AVCONV_IDX then
    system("cp log #{$appli[$appliIdx]["label"]}/#{md5}")
  else
    ret     = IO.popen("wc -l log").readlines
    from    = /([0-9]*) */
    nbLine  = (ret[0].scan(from))[0][0].to_i
    if $appliIdx == HM_IDX then
      system("head -n #{nbLine - 2} log     > log_tmp")
      system("tail -n #{nbLine - 4} log_tmp > #{$appli[$appliIdx]["label"]}/#{md5}")
      File.delete("log_tmp")
    elsif $appliIdx == OPEN_HEVC_IDX then
      system("head -n #{nbLine - 1} log     > #{$appli[$appliIdx]["label"]}/#{md5}")
    end
  end
end
###############################################################################
# run
###############################################################################
def run (binFile, idxFile, nbFile, maxSize)
  print "= #{idxFile.to_s.rjust(nbFile.to_s.size)}/#{nbFile} = #{binFile.ljust(maxSize)}"
  cmd = "#{$exec} #{$appli[$appliIdx]["option"]} #{$sourcePattern}/#{binFile} #{$appli[$appliIdx]["output"]} > log 2> error"
  system(cmd)
  check_error(binFile)
  File.delete("log")
  File.delete("error")
end
###############################################################################
# main
###############################################################################
def main ()
  getopts(ARGV)
  if File.exist?($appli[$appliIdx]["label"]) then
    system("rm -r #{$appli[$appliIdx]["label"]}")
  end
  Dir.mkdir($appli[$appliIdx]["label"])
  
  listFile = getListFile()
  if listFile.length != 0 then
    maxSize  = getMaxSizeFileName(listFile)
    listFile.each_with_index do |binFile,idxFile|
      run(binFile, idxFile+1, listFile.length, maxSize)
    end
  end
end