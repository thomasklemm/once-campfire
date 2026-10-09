class ContentFilters::RemoveSoloUnfurledLinkText < ActionText::Content::Filter
  TWITTER_DOMAINS = %w[ x.com twitter.com ]
  TWITTER_DOMAIN_MAPPING = { "x.com" => "twitter.com" }
  OPENGRAPH_EMBED_CONTENT_TYPE = ActionText::Attachment::OpengraphEmbed::OPENGRAPH_EMBED_CONTENT_TYPE

  # to_plain_text renders every attachment, so skip it when there is no unfurled link to match.
  def applicable?
    url = solo_unfurled_url
    !url.nil? && normalize_tweet_url(url) == normalize_tweet_url(content.to_plain_text)
  end

  def apply
    if trix_body?
      remove_link_text_from_wrapping_div
    else
      remove_link_paragraphs
    end
  end

  private
    def solo_unfurled_url
      ActionText::Attachment::OpengraphEmbed.from_node(unfurled_links.first)&.href if unfurled_links.size == 1
    end

    # Most messages have no embed, and the html shows that more cheaply than a selector search.
    def unfurled_links
      @unfurled_links ||= if content.to_html.include?(OPENGRAPH_EMBED_CONTENT_TYPE)
        fragment.find_all("action-text-attachment[@content-type='#{OPENGRAPH_EMBED_CONTENT_TYPE}']")
      else
        []
      end
    end

    def normalize_tweet_url(url)
      return url unless twitter_url?(url)

      uri = URI.parse(url)

      uri.dup.tap do |u|
        u.host = TWITTER_DOMAIN_MAPPING[uri.host&.downcase] || uri.host
        u.query = nil
      end.to_s
    rescue URI::InvalidURIError
      url
    end

    def twitter_url?(url)
      url.present? && TWITTER_DOMAINS.any? { |domain| url.strip.include?(domain) }
    end

    def trix_body?
      fragment.find_all("div").any?
    end

    def remove_link_text_from_wrapping_div
      fragment.replace("div") { |node| node.tap { |n| n.inner_html = unfurled_links.first.to_s } }
    end

    def remove_link_paragraphs
      fragment.replace("p") do |node|
        if node.at_css("action-text-attachment")
          node
        end
      end
    end
end
