class SitemapsController < ApplicationController
  CACHE_SECONDS = 3600

  def show
    @entries = SitemapEntries.new.entries(base_url)
    response.headers["Cache-Control"] = "public, max-age=#{CACHE_SECONDS}"
    render formats: :xml
  end

  def robots
    body = [
      "User-agent: *",
      "Disallow: /admin",
      "Disallow: /api",
      "Disallow: /login",
      "",
      "Sitemap: #{base_url}/sitemap.xml",
      ""
    ].join("\n")

    response.headers["Cache-Control"] = "public, max-age=#{CACHE_SECONDS}"
    render plain: body
  end

  private

  def base_url
    "#{request.protocol}#{request.host_with_port}"
  end
end
