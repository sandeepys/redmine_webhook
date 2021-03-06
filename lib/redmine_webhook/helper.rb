module RedmineWebhook 
  class Helper
    include ActionView::Helpers
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers
    include IssuesHelper
    include Redmine::I18n
    include ERB::Util
    
	# Return a string used to display a custom value
	def format_value(value, custom_field)
	  format_object(custom_field.format.formatted_value(self, custom_field, value, false), false)
	end
	
    def issue_to_json(issue)
      {
        :payload => {
          :action => 'opened',
          :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
          :url => url_for(:host => Setting.host_name, :controller => 'issues', :action => 'show', :id => issue, :only_path => false)
        }
      }.to_json
    end
    
    def journal_to_json(journal)
      {
        :payload => {
          :action => 'updated',
          :issue => RedmineWebhook::IssueWrapper.new(journal.issue).to_hash,
          :journal => RedmineWebhook::JournalWrapper.new(journal).to_hash,
          :journal_html => details_to_strings(journal.visible_details),
          :url => url_for(:host => Setting.host_name, :controller => 'issues', :action => 'show', :id => journal.issue, :anchor => "change-#{journal.id}", :only_path => false)
        }
      }.to_json
    end
    
    def post(webhook, request_body)
      Thread.start do
        begin
          Faraday.post do |req|
            req.url webhook.url
            req.headers['Content-Type'] = 'application/json'
            req.body = request_body
          end
        rescue => e
          Rails.logger.error e
        end
      end
    end
  end
end
