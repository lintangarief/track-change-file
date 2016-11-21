require_relative 'diff_text'
require 'json'
require 'pathname'
require 'filewatcher'

class FileModify
  def initialize path
    @path = path
    @log_path = Dir.pwd + "/log.txt"
  end

  def captured_new_file file_data
    open(@log_path, 'w') do |file|
      file << [file_data.to_json]
      puts "Captured new File : #{file_data[:content]}"
    end
  end

  def is_file_exist?
    filePath = Pathname.new(@path)
    File.exist?(@path) && filePath.file?
  end

  def get_content_from_text current_file_log
    JSON.parse(JSON.parse(current_file_log).last)["content"]
  end

  def compare_text old_text, new_text
    DiffText.build(old_text, new_text)
  end

  def format_new_data current_file_log, file_data
    current_file_log = JSON.parse(current_file_log)
    current_file_log << file_data.to_s
  end

  def format_file_Data file_lstat, text_in_current_target
    file_data = {
      :mode => file_lstat.mode.to_s,
      :uid => file_lstat.uid.to_s,
      :gid => file_lstat.gid.to_s,
      :size => file_lstat.size.to_s,
      :atime => file_lstat.atime.to_s,
      :mtime => file_lstat.mtime.to_s,
      :ctime => file_lstat.ctime.to_s,
      :content => text_in_current_target.to_s
    }
  end

  def run
    if !is_file_exist?
      puts "File not found!"
      return
    end
    captured
    watch_file

  end

  def captured
    captured_text = File.read(@path)
    open(@path) do |file|
      lstat_target_file = file.lstat
      captured_new_file(format_file_Data(lstat_target_file, captured_text))
    end
  end

  def watch_file
    FileWatcher.new("/Users/moka-arif/track-change-file/target.txt").watch do |data|
      write_file_log data
    end
  end

  def write_file_log data
    file_data = File.open(data)
    file_lstat =  file_data.lstat
    text_in_current_target = file_data.read
    result_format_file = format_file_Data file_lstat, text_in_current_target
    current_file_log = File.read(@log_path)
    text_in_current_log = get_content_from_text current_file_log

    if !compare_text text_in_current_log, text_in_current_target
      open(@log_path, 'w') do |file|
        file << format_new_data(current_file_log, result_format_file.to_json)
        puts "Current Text Log : #{result_format_file[:content]}"
      end
    end
  end
end

file_modify = FileModify.new(ARGV.last)
file_modify.run
