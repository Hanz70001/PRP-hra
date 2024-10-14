class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

# system's databases

class Element < ApplicationRecord
  self.table_name = 't_elements'
end

class Panel < ApplicationRecord
  self.table_name = 't_panels'
end

class Page < ApplicationRecord
  self.table_name = 't_pages'
end

class Context < ApplicationRecord
  self.table_name = 't_contexts'
end

class ContextList < ApplicationRecord
  self.table_name = 't_context_lists'
end

class ContextTemplate < ApplicationRecord
  self.table_name = 't_context_templates'
end

class User < ApplicationRecord
  self.table_name = 't_users'
end

class ServerOption < ApplicationRecord
  self.table_name = 't_serveroptions'
end

class PossibleValue < ApplicationRecord
  self.table_name = 't_possiblevalues'
end

# now user project's databases

class Player < ApplicationRecord
  self.table_name = 't_players'
end

class MessageBox < ApplicationRecord
  self.table_name = 't_messagebox'
end

class SatelliteList < ApplicationRecord
  self.table_name = 't_satellite_list'
end

class SatelliteTemplate < ApplicationRecord
  self.table_name = 't_satellite_template'
end

class SatelliteModule < ApplicationRecord
  self.table_name = 't_modules'
end

class SatelliteConstruction < ApplicationRecord
  self.table_name = 't_sattelite_contruction'
end

class SatelliteValue < ApplicationRecord
  self.table_name = 't_satellite_values'
end