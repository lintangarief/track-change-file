module DiffText
  class DiffBuilder
    def initialize old_text, new_text
      @old_text, @new_text = old_text, new_text
    end

    def text_to_lines text_in_current_target, text_in_current_log
      current_target_by_lines = text_in_current_target.lines.map(&:chomp)
      current_log_by_linnes = text_in_current_log.lines.map(&:chomp)
    end

    def diff
      compare_text @old_text, @new_text
    end

    def compare_text old_text, new_text
      new_text, old_text = new_text.lines.map(&:chomp), old_text.lines.map(&:chomp)
      if new_text.length > old_text.size
        is_not_difference? new_text, old_text
      else
        is_not_difference? old_text, new_text
      end
    end

    def is_not_difference? arr1, arr2
      arr1.each_with_index do |val, index|
        if arr2[index] != val
          return false
          break
        end
        true
      end
    end
  end

  def self.build old_text, new_text
    DiffBuilder.new(old_text, new_text).diff
  end
end
