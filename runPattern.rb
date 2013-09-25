#!/usr/bin/ruby
require "runPatternCommon.rb"
###############################################################################
# grep_info
###############################################################################
def grep_info (info)
  cmd = "grep \"#{info}\" error"
  ret = IO.popen(cmd).readlines
  if ret[0] != nil then
    puts " #{info}"
    return -1
  end
  return 0
end
###############################################################################
# check_yuv
###############################################################################
def check_yuv (binFile)
  md5 = "#{File.basename(binFile, File.extname(binFile))}.md5"

  if $appliIdx == AVCONV_IDX then
    save_md5(md5)
    cmd  = "grep MD5 #{$appli[$appliIdx]["label"]}/#{md5}"
  else
    yuv = "#{File.basename(binFile, File.extname(binFile))}.yuv"
    cmd = "openssl md5 #{yuv}"
  end

  ret  = IO.popen(cmd).readlines
  val1 = ret[ret.size-1].scan(/MD5.*= *(.*)/)[0][0]

  cmd  = "grep MD5 tests/#{md5}"
  ret  = IO.popen(cmd).readlines
  val2 = ret[ret.size-1].scan(/MD5=(.*)/)[0][0]
 
  if val1 != val2 then
    puts " error ="
    exit if $stop == true
  else
    puts " ok    ="
  end
end
###############################################################################
# check_error
###############################################################################
def check_error (binFile)
  return if grep_info("Frame base and tiles enabled not yet implemented") == -1
  if $yuv == true then
    check_yuv(binFile)
    return
  end
  cmd = "grep \"Correct\" error"
  ret = IO.popen(cmd).readlines
  if ret[1] == nil and $appliIdx != HM_IDX then

    md5 = "#{File.basename(binFile, File.extname(binFile))}.md5"
    save_md5(md5)

    if File.exist?("#{$appli[HM_IDX]["label"]}/#{md5}") then
      cmd = "grep -v \"POC\" #{$appli[$appliIdx]["label"]}/#{md5} > #{$appli[$appliIdx]["label"]}_#{md5}"
      system(cmd)
      cmd = "grep -v \"POC\" #{$appli[HM_IDX]["label"]}/#{md5} > #{$appli[HM_IDX]["label"]}_#{md5}"
      system(cmd)
      cmd = "diff #{$appli[$appliIdx]["label"]}_#{md5} #{$appli[HM_IDX]["label"]}_#{md5}"
      ret = IO.popen(cmd).readlines
      File.delete("#{$appli[$appliIdx]["label"]}_#{md5}")
      File.delete("#{$appli[HM_IDX]["label"]}_#{md5}")
      if ret[1] != nil then
	puts " error ="
	exit if $stop == true
      else
	puts " ok    ="
      end
    else
      puts " ="
    end
    
  elsif $appliIdx != HM_IDX then
    
    cmd = "grep \"Incorrect\" error"
    ret = IO.popen(cmd).readlines
    if ret[1] != nil then
      puts " error ="
      exit if $stop == true
    else
      puts " ok    ="
    end
    
  else

    md5 = "#{File.basename(binFile, File.extname(binFile))}.md5"
    save_md5(md5)
    puts " ="
  
  end

end
###############################################################################
# main
###############################################################################
main()
