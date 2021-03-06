require 'openssl'
module Keybox

  ##
  # Use an IO device to retrieve random data.  Usually this is
  # somethine like '/dev/random' but may be anything that can read
  # from by IO.read.
  #
  #   bytes = RandomDevice.random_bytes(42)
  #
  # or
  #
  #   rd = RandomDevice.new
  #   bytes = rd.random_bytes(42)
  #
  # If there is a some other hardware device or some service that
  # provides random byte stream, set it as the default device in this
  # class and it will use it instead of the default.
  #
  #   my_random_device = RandomDevice("/dev/super-random-device")
  #
  # or
  #
  #   RandomDevice.default = "/dev/super-random-device"
  #   my_random_device     = RandomDevice.new
  #   my_random_device.source                        # =>  "/dev/super-random-device"
  #
  # All further instances of RandomDevice will use it as the default.
  #
  # RandomDevice can either produce random bytes as a class or as an
  # instance.
  #
  #   random_bytes = RandomDevice.random_bytes(42)
  #   random_bytes.size                              # => 42
  #
  class RandomDevice
    attr_accessor :source

    def initialize(device = nil)
      if not device.nil? and File.readable?(device) then
        @source = device
      else
        @source = RandomDevice.default
      end
    end

    def random_bytes(count = 1)
      File.read(source,count)
    end

    class << self
      def devices
        @devices ||= [ "/dev/urandom", "/dev/random" ]
      end

      def default
        if not defined? @default then
          devices.each do |device|
            if File.readable?(device) then
              @default = device
              break
            end
          end
        end
        return @default
      end

      def default=(device)
        if File.readable?(device) then
          self.devices << device unless self.devices.include?( device )
          @default = device
        else
          raise ArgumentError, "device #{device} is not readable and therefore makes a bad random device"
        end
      end

      def random_bytes(count = 1)
        File.read(RandomDevice.default,count)
      end
    end
  end


  #
  # A RandomSource uses one from a set of possible source
  # class/modules.  So long as the default item responds to
  # +random_bytes+ it is fine.
  #
  # RandomSource supplies a +rand+ method in the same vein as
  # Kernel#rand.
  #
  class RandomSource
    class << self
      def default_source_classes
        [ ::Keybox::RandomDevice, ::OpenSSL::Random ]
      end

      def source_classes
        @source_classes ||= default_source_classes
      end

      def register(klass)
        if klass.respond_to?("random_bytes") then
          @source_classes << klass unless self.source_classes.include?(klass)
        else
          raise ArgumentError, "class #{klass.name} does not have a 'random_bytes' method"
        end
      end

      def source=(klass)
        register(klass)
        @source = klass
      end

      def source
        if (not defined? @source) or  (not source_classes.include?( @source ) ) then
          self.source_classes.each do |klass|
            if klass.random_bytes(2).length == 2 then
              RandomSource.source = klass
              break
            end
          end
        end
        return @source
      end

      #
      # Behave like Kernel#rand where if no max is specified return
      # a value >= 0.0 but < 1.0.
      #
      # If a max is specified, return an Integer between 0 and
      # upto but not including max.
      #
      def rand(max = nil)
        bytes = source.random_bytes(8)
        num = bytes.unpack("F").first.abs / Float::MAX
        if max then
          num = bytes.unpack("Q").first % max.floor
        end
        return num
      end
    end
  end

  #
  # Randomizer will randomly pick a value from anything that
  # behaves like an array or has a +to_a+ method.  Behaving like an
  # array means having a +size+ or +length+ method along with an +at+
  # method.
  #
  # The source of randomness is determined at runtime.  Any class that
  # can provide a +rand+ method and operates in the same manner
  # as Kernel#rand can be a used as the random source.
  #
  # The item that is being 'picked' from can be any class that has a
  # +size+ method along with an +at+ method.
  #
  #   array = ("aaa"..."zzz").to_a
  #   r = Randomizer.new
  #   r.pick_one_from(array)          # => "lho"
  #   r.pick_count_from(array,5)      # => ["mvt", "tde", "wdu", "ker", "bgc"]
  #
  #
  class Randomizer

    REQUIRED_METHODS = %w( at size )

    attr_reader :random_source

    def initialize(random_source_klass = ::Keybox::RandomSource)
      raise ArgumentError, "Invalid random source class" unless random_source_klass.respond_to?("rand")
      @random_source = random_source_klass
    end

    def pick_one_from(array)
      pick_count_from(array).first
    end

    def pick_count_from(array, count = 1)
      raise ArgumentError, "Unable to pick from object of class #{array.class.name}" unless has_correct_duck_type?(array)
      results = []
      range = array.size
      count.times do
        rand_index = random_source.rand(range)
        results << array.at(rand_index)
      end
      results
    end

    private

    def has_correct_duck_type?(obj)
      (REQUIRED_METHODS & obj.public_methods.map { |m| m.to_s} ).size == REQUIRED_METHODS.size
    end
  end
end
