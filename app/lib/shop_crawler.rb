require 'anemone'
require 'capybara'
require 'capybara/poltergeist'
require 'nkf'

# ネットショップのページをクローリングする
class ShopCrawler
  attr_accessor :window_height, :window_width
  
  CAPYBARA_WINDOW_HEIGHT = 774
  CAPYBARA_WINDOW_WIDTH = 1536
  LOG_FILE_SIZE = 5*1024*1024
  CRAWL_LOG = './log/shop_crawl.txt'
  
  # 初期化
  def initialize(ajax_wait_time = 10)
    @max_wait_time = 1000
    @max_ajax_wait_time = ajax_wait_time
    @session = nil
    init_capybara
    init_anemone
  end


  # capybaraの初期化
  def init_capybara
    @log = Logger.new(CRAWL_LOG, 10, LOG_FILE_SIZE)

    @window_width = CAPYBARA_WINDOW_WIDTH 
    @window_height = CAPYBARA_WINDOW_HEIGHT

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => @max_wait_time, :logger => self, :phantomjs_logger => self, :debug => true, :phantomjs_options => ['--load-images=no',  '--ignore-ssl-errors=yes', '--ssl-protocol=any'], :window_size => [@window_width, @window_height], :screen_size => [@window_width, @window_height] } )
    end
    
    Capybara.default_driver = :poltergeist
    Capybara.javascript_driver = :poltergeist
    Capybara.default_selector = :xpath
  end

  # Anemoneの初期化
  def init_anemone
    @anemone_option = {
      :user_agent => ENV["CRAWL_USER_AGENT"],
      :depth_limit => 0,
    }
  end

  # capybaraセッションの作成
  def create_session
    session = Capybara::Session.new(:poltergeist)    
    session.driver.headers = { 'User-Agent' => ENV["CRAWL_USER_AGENT"] }
    session
  end

  # ログ出力
  def puts(s)
    @log.debug(s)
  end

  
  # ログ出力
  def write(s)
    @log.debug(s)
  end


  # ページを取得する
  def crawl_page(url)
    result = nil
    begin
      @url = url
      @log.debug("in crawl_page url=#{@url}")
      Anemone.crawl(@url, @anemone_option) do |anemone|
        anemone.on_every_page do |page|
          if page != nil && page.body != nil
            result = NKF.nkf('-wxm0', page.body)
            @log.info("crawl result: url=#{@url}\r\n#{result}")
          else
            result = nil
            @log.error("in crawl_page. page is nil. url=#{@url}")
          end
        end
      end
    rescue => e
      if url.blank?
        url = ""
      end
      msg = "Exception in crawl_page url=#{url}, exception class=#{e.class.to_s}, msg=#{e.to_s}"
      @log.error(msg)
    end
    result
  end


  # JavaScritpの実行を待ってページを取得する
  def crawl_page_js(url)
    result = nil
    begin
      @url = url
      @log.debug("in crawl_page_js url=#{@url}")
      @session = create_session if @session.blank?
      @session.visit @url
      
      wait_for_ajax(@session)
      result = NKF.nkf('-wxm0', @session.html)
      @log.info("crawl result: url=#{@url}\r\n#{result}")
      
      @session.driver.quit
      @session = nil
    rescue => e
      if url.blank?
        url = ""
      end
      msg = "Exception in crawl_page url=#{url}, exception class=#{e.class.to_s}, msg=#{e.to_s}"
      @log.error(msg)
    end
    result
  end


  # java scriptの実行を待つ
  def wait_for_ajax(session)
    begin
      Timeout.timeout(@max_ajax_wait_time) do
        active = session.evaluate_script('jQuery.active')
        until active == 0
          sleep 0.5
          active = session.evaluate_script('jQuery.active')
        end
      end
    rescue Timeout::Error => e
      if @url.blank?
        @url = ""
      end
      msg = "Exception in wait_for_ajax. ajax wait timeout occured, url=#{@url}, msg=#{e.to_s}"
      @log.error(msg)
    rescue => e
      if @url.blank?
        @url = ""
      end
      msg = "Exception in wait_for_ajax. url=#{@url}, class=#{e.class.to_s}, msg=#{e.to_s}" 
      @log.error(msg)
    end
  end
end
