require 'open-uri'
require 'nokogiri'

require 'vainglory/scrape/ability'
require 'vainglory/scrape/status'

module Vainglory
  class ScrapeHeroFromOfficial
    def initialize(url)
      charset = nil
      html = open(url) do |f|
        charset = f.charset
        f.read
      end
      @doc = Nokogiri::HTML.parse(html, nil, charset)
      get_hero_name
      get_excerpt
      get_status
      get_ability
    end

    attr_accessor :doc, :name, :statuses, :excerpt, :abilities

    def get_hero_name
      @name = @doc.xpath("//div[@class='md-show']/h1").text
    end

    def get_excerpt
      @excerpt = @doc.css("p.excerpt").text
    end

    def get_status
      status_array = []
      # h6とh4の子孫要素を持つdivを取得
      @doc.xpath("//div[@id='stats-wrapper']//div[h6 and h4]").each do |status_div|
        status = Vainglory::Status.new
        status.name = status_div.css("h6").text

        status_str = status_div.css("h4").text.strip
        status.start = match_status_string(status_str, /\d+(?:.\d+)?/)
        status.glow = match_status_string(status_str, /\((\+\d+(?:\.\d+)?)\)/)
        status_array.push(status)
      end
      @statuses = status_array
    end

    def get_ability
      ability_array = []
      @doc.css("div.ability").xpath("./div[@class='text' and p[@class='mb0 md-show']]").each do |ability_div|
        ability = Vainglory::Ability.new
        ability.name = ability_div.css("h5.white").text
        ability.effect = ability_div.css("p.mb0").text 
        ability_array.push(ability)
      end
      @abilities = ability_array
    end

    def to_hash
       status_array = []
       @statuses.each do |status|
         status_array.push(status.to_hash)
       end

       ability_array = []
       @abilities.each do |ability|
         ability_array.push(ability.to_hash)
       end

      {
        name: @name,
        #excerpt: @excerpt,
        status: status_array#,
        #ability: ability_array
      }
    end

    private
      def match_status_string(status_string, regex)
        if status_string.empty? 
          "Not Written"
        elsif status_string.match(/N\/A/)
          Float::NAN
        else
          get_float_from_match(status_string.match(regex))
        end
      end

      # キャプチャを1つ使っていた場合は、キャプチャ部分を数値に変換する
      # キャプチャを使っていない場合は、マッチした部分を数値に変換する
      # キャプチャを2つ以上使うケースはnilを返す
      # 引数がnilの時はnilを返す
      def get_float_from_match(match_data)
        if match_data.nil?
          nil
        elsif !match_data[1].nil?
          match_data[1].to_f
        else
          match_data[0].to_f 
        end
      end
  end
end