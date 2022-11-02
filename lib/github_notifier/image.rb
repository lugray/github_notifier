module GithubNotifier
  module Image
    GREEN          = '22DD22'
    RED            = 'DD0000'
    PURPLE         = 'A128CA'
    GRAY           = '888888'
    WHITE          = 'FFFFFF'
    SIZE           = 64
    INPUT_DENSITY  = 1200 # Internal canvas
    OUTPUT_DENSITY = 325 # Seems to work best with xbar

    class << self

    def get(name, color = nil)
      fname = name
      fname += "-#{color}" if color
      color ||= '000000'
      @memo ||= {}
      @memo[fname] ||= begin
        output = File.join(ROOT, "images/#{fname}.png")
        unless File.exist?(output)
          input = File.join(ROOT, "images/#{name}.svg")
          create(input, output, color)
        end
        Base64.strict_encode64(File.read(output))
      end
    end

    def create(input, output, color)
      args = %w(convert -background transparent)
      args += %W(-fuzz 80% -fill ##{color} -opaque #000000) if color
      args += %W(-units pixelsperinch -density #{INPUT_DENSITY} -resize #{SIZE}x#{SIZE} -gravity center -extent #{SIZE}x#{SIZE})
      args << input
      args += %W(-density #{OUTPUT_DENSITY})
      args << output
      system(*args)
    end
    end
  end
end
