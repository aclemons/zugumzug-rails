module SortHelper
  def random_sort(collection)
    collection.sort_by { |a| SecureRandom.uuid }
  end

  def random_sort!(collection)
    collection.sort_by! { |a| SecureRandom.uuid }
  end
end
