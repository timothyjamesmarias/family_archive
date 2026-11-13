module Admin
  # The "Insert embed" dialog on rich text forms: pick a kind, pick a record
  # from its menu, set its options. Creating returns the attachment markup for the
  # embed-picker controller to put into the editor.
  class EmbedsController < BaseController
    def new
      @kind = Embed::KINDS.key?(params[:kind]) ? params[:kind] : Embed::KINDS.keys.first
      @options = Embed.menu_options(@kind)
    end

    def create
      @embed = Embed.build_for(**params.expect(embed: [ :kind, :embeddable_id, options: {} ]).to_h.symbolize_keys)
      @embed.save!
    end
  end
end
