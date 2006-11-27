require 'keybox'
require 'keybox/application/password_generator'

context "Keybox Password Generator Application" do
    setup do
    end

    specify "nil argv should do nothing" do
        kpg = Keybox::Application::PasswordGenerator.new(nil)
        kpg.error_message.should_be nil
    end

    specify "invalid options set the error message, exit 1 and have output on stderr" do
        kpg = Keybox::Application::PasswordGenerator.new(["--invalid-option"])
        kpg.stderr = StringIO.new
        begin
            kpg.run
        rescue SystemExit => se
            kpg.error_message.should_satisfy { |msg| msg =~ /Try.*--help/m }
            kpg.stderr.string.should_satisfy { |msg| msg =~ /Try.*--help/m }
            se.status.should_equal 1
        end
    end

    specify "can set the algorithm" do
        kpg = Keybox::Application::PasswordGenerator.new(["--alg", "pron"])
        kpg.stdout = StringIO.new
        kpg.run
        kpg.options.algorithm.should_equal :pronounceable
    end
    
    specify "can specify the number of passwords created " do
        kpg = Keybox::Application::PasswordGenerator.new(["--num", "4"])
        kpg.stdout = StringIO.new
        kpg.run

        kpg.options.number_to_generate.should_equal 4
        kpg.stdout.string.split(/\s+/).size.should_equal 4
    end

    specify "help has output on stdout and exits 0" do
        kpg = Keybox::Application::PasswordGenerator.new(["--h"]) 
        kpg.stdout = StringIO.new
        begin
            kpg.run
        rescue SystemExit => se
            se.status.should_equal 0
            kpg.stdout.string.length.should_be > 0
        end
    end

    specify "minimum length can be set and all generated passwords will have length >= minimum length" do
        kpg = Keybox::Application::PasswordGenerator.new(["--min", "4"]) 
        kpg.stdout = StringIO.new
        kpg.run

        kpg.options.min_length.should_equal 4
        kpg.stdout.string.split("\n").each do |pass|
            pass.length.should_satisfy { |s| s >= kpg.options.min_length }
        end
    end

    specify "maximum length can be set and all generated passwords will have length <= maximum length" do
        kpg = Keybox::Application::PasswordGenerator.new(["--max", "4", "--min", "3"]) 
        kpg.stdout = StringIO.new
        kpg.run

        kpg.options.max_length.should_equal 4
        kpg.stdout.string.split("\n").each do |pass|
            pass.length.should_satisfy { |s| s <= 4 }
        end
    end

    specify "setting an invalid required symbol set exits 1 and outputs data on stderr" do
        kpg = Keybox::Application::PasswordGenerator.new(["--req","bunk"])
        kpg.stderr = StringIO.new
        begin
            kpg.run
        rescue SystemExit => se
            kpg.error_message.should_satisfy { |msg| msg =~ /Try.*--help/m }
            kpg.stderr.string.should_satisfy { |msg| msg =~ /Try.*--help/m }
            se.status.should_equal 1
        end
 
    end

    specify "setting an invalid use symbol set exits 1 and outputs data on stderr" do
        kpg = Keybox::Application::PasswordGenerator.new(["--use","bunk"])
        kpg.stderr = StringIO.new
        begin
            kpg.run
        rescue SystemExit => se
            kpg.error_message.should_satisfy { |msg| msg =~ /Try.*--help/m }
            kpg.stderr.string.should_satisfy { |msg| msg =~ /Try.*--help/m }
            se.status.should_equal 1
        end
 
    end

    specify "setting an valid use symbol works" do
        kpg = Keybox::Application::PasswordGenerator.new(["--use","l"])
        kpg.stdout = StringIO.new
        kpg.run
        kpg.options.use_symbols.should_include Keybox::SymbolSet::LOWER_ASCII
        kpg.stdout.string.split(/\s+/).size.should_equal 6
    end

    specify "setting an valid required symbol works" do
        kpg = Keybox::Application::PasswordGenerator.new(["--req","l"])
        kpg.stdout = StringIO.new
        kpg.run
        kpg.options.require_symbols.should_include Keybox::SymbolSet::LOWER_ASCII
        kpg.stdout.string.split(/\s+/).size.should_equal 6
    end





end
