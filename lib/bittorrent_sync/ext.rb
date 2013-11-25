module BitTorrentSync
  class ::Hash
    def keep_only(selected)
      raise Exception unless selected.kind_of?(Array)
      self.delete_if{|key| !selected.include?(key.to_sym) }
    end
  end
end