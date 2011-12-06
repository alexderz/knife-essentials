require 'chef_fs/knife'

class Chef
  class Knife
    class Ls < ChefFS::Knife
      banner "ls [-dR] [PATTERN1 ... PATTERNn]"

      option :recursive,
        :short => '-R',
        :boolean => true,
        :description => "List directories recursively."
      option :bare_directories,
        :short => '-d',
        :boolean => true,
        :description => "When directories match the pattern, do not show the directories' children."

      def run
        patterns = name_args.length == 0 ? [""] : name_args
        base_dir = "/" + pwd_relative_to(chef_repo)

        # Get the matches (recursively)
        results = []
        patterns.each do |pattern|
          chef_fs.list(ChefFS::FilePattern::relative_to(base_dir, pattern)).each do |result|
            if result.exists?
              results << result
              if config[:recursive]
                results += list_child_dirs_recursive(result)
              end
            end
          end
        end

        results = results.sort_by { |result| result.path }

        # Print the matches
        if config[:bare_directories]
          print_result_paths results
        elsif results.length == 1 && results[0].dir?
          print_result_paths results[0].children
        else
          print_result_paths results.select { |result| !result.dir? }
          results.select { |result| result.dir? }.each do |result|
            puts ""
            puts "#{result.path}:"
            print_results(result.children.map { |result| result.name }.sort, "  ")
          end
        end
      end

      def list_child_dirs_recursive(result)
        results = result.children.select { |child| child.dir? }.to_a
        results.each do |child|
          results += list_recursive(child)
        end
        results
      end

      def print_result_paths(results, indent = "")
        print_results(results.map { |result| result.path }, indent)
      end

      def print_results(results, indent)
        return if results.length == 0

        print_space = results.map { |result| result.length }.max + 2
        # TODO: tput cols is not cross platform
        columns = Integer(`tput cols`)
        current_column = 0
        results.each do |result|
          if current_column + print_space > columns
            puts ""
            current_column = 0
          end
          if current_column == 0
            print indent
            current_column += indent.length
          end
          print result + (' ' * (print_space - result.length))
          current_column += print_space
        end
        puts ""
      end
    end
  end
end

