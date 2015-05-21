require 'erubis'

class OutcomePresenter < NodePresenter
  class OutcomeTemplateMissing < StandardError; end

  def initialize(i18n_prefix, node, state = nil, options = {})
    @options = options
    super(i18n_prefix, node, state)
  end

  def title
    translate!('title')
  end

  def translate!(subkey)
    output = super(subkey)
    if output
      output.gsub!(/\+\[data_partial:(\w+):(\w+)\]/) do |match|
        render_data_partial($1, $2)
      end
    end

    output
  end

  def calendar
    @node.evaluate_calendar(@state)
  end

  def has_calendar?
    calendar.present?
  end

  def has_body?
    use_template? || super()
  end

  def body
    if use_template?
      view_context = @state.dup
      view_context.extend(ActionView::Helpers::NumberHelper)
      govspeak = ERB.new(erb_template_from_file).result(view_context.instance_eval { binding })
      GovspeakPresenter.new(govspeak).html
    else
      super()
    end
  end

  def erb_template_from_file
    unless File.exists?(erb_template_path)
      raise OutcomeTemplateMissing
    end

    File.read(erb_template_path)
  end

  def erb_template_path
    @options[:erb_template_path] || default_erb_template_path
  end

  def default_erb_template_path
    Rails.root.join("lib/smart_answer_flows/#{@node.flow_name}/#{name}.txt.erb")
  end

  private

  def use_template?
    @node.use_template?
  end

  def render_data_partial(partial, variable_name)
    data = @state.send(variable_name.to_sym)

    partial_path = ::SmartAnswer::FlowRegistry.instance.load_path.join("data_partials", "_#{partial}")
    ApplicationController.new.render_to_string(file: partial_path.to_s, layout: false, locals: {variable_name.to_sym => data})
  end
end
