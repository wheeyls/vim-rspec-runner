require 'vimrunner'
require 'tempfile'

describe "spec runner plugin" do
  let (:path_to_plugin) { File.expand_path(File.join(File.dirname(__FILE__), '..')) }
  let (:path_to_formatter) { File.expand_path(File.join(path_to_plugin, 'plugin', 'formatter', 'vim_quickfix_formatter.rb')) }
  let (:path_to_sample_spec) { File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'spec_sample.rb')) }
  let (:spec_file) {
    f = Tempfile.new("vim-rspec-runner")
    f.write(IO.read(path_to_sample_spec))
    f.close
    f
  }
  let (:formatter_class) { "RSpec::Core::Formatters::VimQuickfixFormatter" }

  before(:all) do
    @vim = Vimrunner.start
    @vim.add_plugin(path_to_plugin, 'plugin/rspec-runner.vim')
  end

  after(:all) do
    @vim.kill
    spec_file.unlink
  end

  it "returns the path to the file containing the custom formatter for the relevant version of Rspec" do
    @vim.command('echo rspecrunner#PathToFormatter("2.x")').should eq path_to_formatter

    path_to_rspec_1_formatter = File.expand_path(File.join(path_to_plugin, 'plugin', 'formatter', 'vim_quickfix_formatter_rspec1.rb'))
    @vim.command('echo rspecrunner#PathToFormatter("1.x")').should eq path_to_rspec_1_formatter
  end

  it "returns the namespaced class of the selected formatter for the relevant version of Rspec" do
    @vim.command(%Q{echo rspecrunner#FormatterClass("2.x")}).should eq "RSpec::Core::Formatters::VimQuickfixFormatter"
  end

  it "returns the current version of Rspec" do
    # TODO: before you're done figure out if you want this to be more granular - e.g. rspec 1 checks
    @vim.command("echo rspecrunner#RspecVersion()").should eq "2.x"
  end

  it "returns the name of the spec file to be run" do
    @vim.edit(spec_file.path)
    @vim.command("echo rspecrunner#SpecFilePath()").should eq spec_file.path
  end

  it "returns the command to be run to execute all specs in a file" do
    rspec_command = "bundle exec rspec -r #{path_to_formatter} -f #{formatter_class} #{spec_file.path}"
    @vim.edit(spec_file.path)
    @vim.command("echo rspecrunner#RspecCommand()").should eq rspec_command
  end

  it "runs all the specs in the file in a quickfix list" do
    @vim.edit(spec_file.path)
    @vim.command("call rspecrunner#RunSpecsFile()")
    @vim.command("echo getqflist()").should_not eq "[]"
  end
end
