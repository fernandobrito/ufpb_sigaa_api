# Create programs table
class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
