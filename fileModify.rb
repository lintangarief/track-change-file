require_relative 'diff_text'
require 'json'
require 'pry'
require 'benchmark'

class FileModify
  def initialize path
    @path = path
    @log_path = Dir.pwd + "/log.txt"
  end

  def track_file
    captured_text = File.read(@path)
    open(@path) do |file|
      lstat_target_file = file.lstat
      captured_new_file(format_file_Data(lstat_target_file, captured_text))

      file.seek(0,
        IO::SEEK_END)
      case RUBY_PLATFORM
      when /bsd/,
          /darwin/
        require 'rb-kqueue'
        queue = KQueue::Queue.new
        queue.watch_file(@path, :extend) do
          yield file
        end
        queue.run
      when /linux/
        require 'rb-inotify'
        queue = INotify::Notifier.new
        queue.watch(@path, :modify) do
          yield file.read
        end
        queue.run
      else
        loop do
          changes = file.read
          unless changes.empty?
            yield changes
          end
          sleep 1.0
        end
      end
    end
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

    track_file do |data|
      file_lstat = data.lstat
      text_in_current_target = File.read(data)
      file_data = format_file_Data file_lstat, text_in_current_target
      current_file_log = File.read(@log_path)
      text_in_current_log = get_content_from_text current_file_log

      if !compare_text text_in_current_log, text_in_current_target
        open(@log_path, 'w') do |file|
          file << format_new_data(current_file_log, file_data.to_json)
          puts "Current Text Log : #{file_data[:content]}"
        end
      end

    end
  end
end

file_modify = FileModify.new(ARGV.last)
file_modify.run
