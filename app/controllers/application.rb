# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
  include LoginSystem
  before_filter :reset_local_cache, :fire_triggers
  after_filter :reset_local_cache

  protected

  def error(message = "Record not found...", options = { })
    @message = message.to_s
    render :template => 'articles/error', :status => options[:status] || 404
  end

  def current_user
    if @current_user.nil?
      @current_user = session[:user_id] && User.find(session[:user_id])
    end
    @current_user
  end
  helper_method :current_user

  def authorized?
    current_user && authorize?(current_user)
  end

  def fire_triggers
    Trigger.fire
  end

  def reset_local_cache
    CachedModel.cache_reset
    @current_user = nil
  end

  # Axe?
  def server_url
    this_blog.base_url
  end

  def cache
    $cache ||= SimpleCache.new 1.hour
  end

  @@blog_id_for = Hash.new

  # The Blog object for the blog that matches the current request.  This is looked
  # up using Blog.find_blog and cached for the lifetime of the controller instance;
  # generally one request.
  def this_blog
    @blog ||= if @@blog_id_for[blog_base_url]
                Blog.find(@@blog_id_for[blog_base_url])
              else
                returning(Blog.find_blog(blog_base_url)) do |blog|
                  @@blog_id_for[blog_base_url] = blog.id
                end
              end
  end
  helper_method :this_blog

  def reset_blog_ids
    @@blog_id_for = {}
  end

  # The base URL for this request, calculated by looking up the URL for the main
  # blog index page.  This is matched with Blog#base_url to determine which Blog
  # is supposed to handle this URL
  def blog_base_url
    url_for(:controller => '/articles').gsub(%r{/$},'')
  end

  def add_to_cookies(name, value, path=nil, expires=nil)
    cookies[name] = { :value => value, :path => path || "/#{controller_name}",
                       :expires => 6.weeks.from_now }
  end
end

