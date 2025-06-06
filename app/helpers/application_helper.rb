module ApplicationHelper
  include Pagy::Frontend

  def back_path
    @back_path || root_path
  end

  def back_to_from_request
    # remove the back_to params from the query string to avoid creating recusive redirects
    uri = URI.parse(request.fullpath)
    uri.query = uri.query&.split("&")&.reject { |param| param.start_with?("back_to=") }&.join("&")
    uri.to_s
  end

  def active_link_to(text = nil, path = nil, active_class: "", **options, &)
    path ||= text

    classes = active_class.presence || "active"
    options[:class] = class_names(options[:class], classes) if current_page?(path)

    return link_to(path, options, &) if block_given?

    link_to text, path, options
  end

  def footer_credits
    maintainers = [
      link_to("@adrienpoly", "https://github.com/adrienpoly", target: "_blank", class: "link", alt: "Adrien Poly"),
      link_to("@marcoroth", "https://github.com/marcoroth", target: "_blank", class: "link", alt: "Marco Roth")
    ].shuffle.join(" and ")
    output = ["Made with"]
    output << heroicon(:heart, variant: :solid, size: :sm, class: "text-primary inline")
    output << "for the Ruby community by"
    output << maintainers
    output << "and wonderful"
    output << link_to("contributors", "https://github.com/rubyevents/rubyevents/graphs/contributors", target: "_blank", class: "link")
    output << "using an"
    output << link_to("edge stack.", uses_path, class: "link")
    sanitize(output.join(" "), tags: %w[a span svg path], attributes: %w[href target class alt d xmlns viewBox fill])
  end

  def canonical_url
    content_for?(:canonical_url) ? content_for(:canonical_url) : "https://www.rubyevents.org#{request.path}"
  end
end
