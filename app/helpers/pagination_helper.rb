=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

module PaginationHelper
  def paginate(collection)
    @current_page = collection.current_page
    @total_pages = collection.page_count
    items = [:previous] + (1..collection.page_count).to_a + [:next]
    links = items.map do |item|
      item.is_a?(Fixnum) ?
          page_number(item) :
          send(item)
    end.join
    html_tag(:div, links, class: 'pagination').html_safe
  end

  private
  def page_number(page)
    if page == @current_page
      html_tag(:em, page, class: 'current')
    else
      link(page, page)
    end
  end

  def previous
    previous_text = 'Previous'
    if @current_page > 1
      link(previous_text, @current_page - 1)
    else
      html_tag(:span, previous_text, class: 'disabled')
    end
  end

  def next
    next_text = 'Next'
    if @current_page < @total_pages
      link(next_text, @current_page + 1)
    else
      html_tag(:span, next_text, class: 'disabled')
    end
  end

  def link(text, target)
    html_tag(:a, text, href: url_for(params.merge(page: target)))
  end

  def html_tag(name, value, attributes = {})
    string_attributes = attributes.inject('') do |attrs, pair|
      unless pair.last.nil?
        attrs << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
      end
      attrs
    end
    "<#{name}#{string_attributes}>#{value}</#{name}>"
  end
end
