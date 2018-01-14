module Api
  require 'uri'
  
  class AmazonPagesController < ApplicationController
    def index
      msg = "This is etbl_s top page."
      render json: msg
    end
    
    #パラメーター形式： http://localhost:8080/index.html?url=https://www.amazon.co.jp...../
    def crawl
      result = nil
      begin
        url = URI.escape(params[:url]) if params[:url].present?
        if (https?(url) || http?(url)) && url =~ /www\.amazon\./
          logger.info("in carwl. params= #{params.to_s}")
          shop_crawl = ShopCrawler.new
          result = shop_crawl.crawl_page_js(url)
        else
          result = "error! not valid url!"
          logger.error("in carwl. url param error. It is not amazon's url = #{url}")
        end
      rescue => e
        logger.error(e.message)
        result = "ebtl_s_error=#{e.message}.ebtl_s_error_end."
      end
      render json: result
    end

    def https?(str)
      begin
        uri = URI.parse(str)
      rescue URI::InvalidURIError
        return false
      end
      return uri.scheme == 'https'
    end

    def http?(str)
      begin
        uri = URI.parse(str)
      rescue URI::InvalidURIError
        return false
      end
      return uri.scheme == 'http'
    end
    
  end
end