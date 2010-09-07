class GitHooks
  
  def self.pre_commit
    catch_forgotten_debugger
    catch_incomplete_merge
    catch_work_in_progress
    run_tests if committing_to_master?
  end
  
  def self.post_merge
    pre_commit
  end
  
  private
    def self.amending?
      `ps | grep \`ps -f | grep #{$$} | awk '{print $3}' | head -n 1\` | grep -e "--amend"` != ""
    end

    
    def self.forgotten_debugger?
      files_with_debugger != ""
    end

    def self.incomplete_merge?
      files_with_incomplete_merge != ""
    end

    def self.files_with_incomplete_merge
      `egrep -rls "^<<<<<<< |^>>>>>>> |^=======$" * | xargs file | egrep 'script|text' | awk -F: '{print $1}'`
    end

    def self.forgotten_work_in_progress?
      `git log --oneline --author=\`git config --get-all user.email | sed s/@.*//g\` -n 5 | grep -i wip` != ""
    end

    def self.files_with_debugger
      `grep -rls "require 'ruby-debug'; debugger" *`
    end

    def self.committing_to_master?
      `git rev-parse --abbrev-ref HEAD` == "master"
    end
    
    def self.run_tests
      puts "Running tests..."
      `rake test > /dev/null 2>&1 && bundle exec cucumber features > /dev/null 2>&1`
      if $? != 0
        puts "Tests failed"
        exit(1)
      end
    end
    
    def self.catch_forgotten_debugger
      return unless forgotten_debugger?
      puts "Found debug statement in the following files, you should remove it:"
      puts files_with_debugger
      exit(1)
    end
    
    def self.catch_incomplete_merge
      return unless incomplete_merge?
      puts "Looks like you've not finished merging in a conflict:"
      puts files_with_incomplete_merge
      exit(1)
    end
    
    def self.catch_work_in_progress
      return unless forgotten_work_in_progress? && !amending?
      puts "Looks like one of your previous commits was a 'Work in Progress', sure you didn't mean to amend the commit?"
      exit(1)
    end
end