defmodule ProjectZek.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "character_data" do
    field :account_id, :integer
    field :name, :string
    field :last_name, :string
    field :title, :string
    field :suffix, :string
    field :zone_id, :integer
    field :y, :float
    field :x, :float
    field :z, :float
    field :heading, :float
    field :gender, :integer
    field :race, :integer
    field :class, :integer
    field :level, :integer
    field :deity, :integer
    field :birthday, :integer
    field :last_login, :integer
    field :time_played, :integer
    field :level2, :integer
    field :anon, :integer
    field :gm, :integer
    field :face, :integer
    field :hair_color, :integer
    field :hair_style, :integer
    field :beard, :integer
    field :beard_color, :integer
    field :eye_color_1, :integer
    field :eye_color_2, :integer
    field :exp, :integer
    field :aa_points_spent, :integer
    field :aa_exp, :integer
    field :aa_points, :integer
    field :points, :integer
    field :cur_hp, :integer
    field :mana, :integer
    field :endurance, :integer
    field :intoxication, :integer
    field :str, :integer
    field :sta, :integer
    field :cha, :integer
    field :dex, :integer
    field :int, :integer
    field :agi, :integer
    field :wis, :integer
    field :zone_change_count, :integer
    field :hunger_level, :integer
    field :thirst_level, :integer
    field :pvp_status, :integer
    field :air_remaining, :integer
    field :autosplit_enabled, :integer
    field :mailkey, :string
    field :firstlogon, :integer
    field :e_aa_effects, :integer
    field :e_percent_to_aa, :integer
    field :e_expended_aa_spent, :integer
    field :boatid, :integer
    field :boatname, :string
    field :famished, :integer
    field :is_deleted, :integer
    field :showhelm, :integer
    field :fatigue, :integer, default: 0

    has_many :kills, ProjectZek.Characters.PvpEntry,
      foreign_key: :killer_id,
      references: :id

    has_many :deaths, ProjectZek.Characters.PvpEntry,
      foreign_key: :victim_id,
      references: :id

    has_one :pvp_stat, ProjectZek.Characters.PvpStat,
      foreign_key: :character_data_id,
      references: :id
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :account_id,
      :name,
      :last_name,
      :title,
      :suffix,
      :zone_id,
      :y,
      :x,
      :z,
      :heading,
      :gender,
      :race,
      :class,
      :level,
      :deity,
      :birthday,
      :last_login,
      :time_played,
      :level2,
      :anon,
      :gm,
      :face,
      :hair_color,
      :hair_style,
      :beard,
      :beard_color,
      :eye_color_1,
      :eye_color_2,
      :exp,
      :aa_points_spent,
      :aa_exp,
      :aa_points,
      :points,
      :cur_hp,
      :mana,
      :endurance,
      :intoxication,
      :str,
      :sta,
      :cha,
      :dex,
      :int,
      :agi,
      :wis,
      :zone_change_count,
      :hunger_level,
      :thirst_level,
      :pvp_status,
      :air_remaining,
      :autosplit_enabled,
      :mailkey,
      :firstlogon,
      :e_aa_effects,
      :e_percent_to_aa,
      :e_expended_aa_spent,
      :boatid,
      :boatname,
      :famished,
      :is_deleted,
      :showhelm,
      :fatigue
    ])
    |> validate_required([
      :account_id,
      :name,
      :last_name,
      :title,
      :suffix,
      :zone_id,
      :y,
      :x,
      :z,
      :heading,
      :gender,
      :race,
      :class,
      :level,
      :deity,
      :birthday,
      :last_login,
      :time_played,
      :level2,
      :anon,
      :gm,
      :face,
      :hair_color,
      :hair_style,
      :beard,
      :beard_color,
      :eye_color_1,
      :eye_color_2,
      :exp,
      :aa_points_spent,
      :aa_exp,
      :aa_points,
      :points,
      :cur_hp,
      :mana,
      :endurance,
      :intoxication,
      :str,
      :sta,
      :cha,
      :dex,
      :int,
      :agi,
      :wis,
      :zone_change_count,
      :hunger_level,
      :thirst_level,
      :pvp_status,
      :air_remaining,
      :autosplit_enabled,
      :mailkey,
      :firstlogon,
      :e_aa_effects,
      :e_percent_to_aa,
      :e_expended_aa_spent,
      :boatid,
      :famished,
      :is_deleted,
      :showhelm
    ])
    |> unique_constraint(:name)
  end
end
