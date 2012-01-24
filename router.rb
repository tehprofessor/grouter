module	Router

	class RouteMap
		class << self
			attr_accessor :route_root, :parsed_route, :routes_via_get, :routes_via_post, :routes_via_destroy, :routes_via_update, :final_route
			def initialize
				
			end
			def routes_via_get
				unless @routes_via_get
					@routes_via_get = []
				end
				@routes_via_get
			end

			def routes_via_update
				unless @routes_via_update
					@routes_via_update = []
				end
				@routes_via_update
			end

			def routes_via_post
				unless @routes_via_post
					@routes_via_post = []
				end
				@routes_via_post
			end

			def routes_via_destroy
				unless @routes_via_destroy
					@routes_via_destroy = []
				end
				@routes_via_destroy
			end
		end

	end

	module Create
		def self.root(args)
			RouteMap.route_root = {controller: args[:controller], action: args[:action], path: ["/"], request_method: "GET" }
		end

		def self.resource(resource)
			# resource should be a string with the name
			@routes = %w[index show new create edit update destroy].each do |rest|
				@controller = resource.downcase
				case rest
					when 'index'
						@action = 'index'
						@path = ["#{@controller}"]
						@request_method = "GET"
					when 'show'
						@action = 'show'
						@path = ["#{@controller}", :id]
						@request_method = "GET"
					when 'new'
						@action = 'new'
						@path = ["#{@controller}", "new"]
						@request_method = "GET"
					when 'create'
						@action = 'create'
						@path = ["#{@controller}"]
						@request_method = "POST"
					when 'edit'
						@action = 'edit'
						@path = ["#{@controller}", :id, "edit"]
						@request_method = "GET"
					when 'update'
						@action = 'update'
						@path = ["#{@controller}", :id]
						@request_method = "POST"
					when 'destroy'
						@action = 'destroy'
						@path = ["#{@controller}", :id]
						@request_method = "DESTROY"
				end
				case @request_method
				when "GET"
					Router::RouteMap.routes_via_get << {:controller => resource, :action => @action, :path => @path, :request_method => @request_method}
				when "POST"
					Router::RouteMap.routes_via_post << {:controller => resource, :action => @action, :path => @path, :request_method => @request_method}
				when "DESTROY"
					Router::RouteMap.routes_via_destroy << {:controller => resource, :action => @action, :path => @path, :request_method => @request_method}
				when "UPDATE"
					Router::RouteMap.routes_via_update << {:controller => resource, :action => @action, :path => @path, :request_method => @request_method}
				end
			end
			@routes
		end

		def self.static(args)
			# defaults to "GET"
			args[:path] = args[:path].split("/").collect{|x| x.length >= 1 ? x : nil }.compact
			unless args[:request_method]
				Router::RouteMap.routes_via_get << {:controller => args[:controller], :action => args[:action], :path => args[:path], :request_method => "GET"}
			else
				case args[:request_method]
				when "GET"
					Router::RouteMap.routes_via_get << {:controller => args[:controller], :action => args[:action], :path => args[:path], :request_method => args[:request_method]}
				when "POST"
					Router::RouteMap.routes_via_post << {:controller => args[:controller], :action => args[:action], :path => args[:path], :request_method => args[:request_method]}
				when "DESTROY"
					Router::RouteMap.routes_via_destroy << {:controller => args[:controller], :action => args[:action], :path => args[:path], :request_method => args[:request_method]}
				when "UPDATE"
					Router::RouteMap.routes_via_update << {:controller => args[:controller], :action => args[:action], :path => args[:path], :request_method => args[:request_method]}
				end
			end
		end

		def self.routify(env_path, env_req_method)
			@path_pieces = env_path.split("/").collect{|piece| piece.length >= 1 ? piece : nil}.compact
			Router::RouteMap.parsed_route = {path: @path_pieces, request_method: env_req_method}
		end
	end

	def self.route_map
		@route_map
	end

	def self.find(routes)
		routes.each do |r|
			@countr = 0
			@symbol_countr = 0
			r[:path].each_with_index do |x, n|
				unless x.class == Symbol
					if Router::RouteMap.parsed_route[:path][n] == x
						@countr += 1
					end
				else
					@symbol_countr += 1
				end
			end
			if (@countr + @symbol_countr) == r[:path].size
				Router::RouteMap.final_route = r
				Router::RouteMap.final_route[:raw_path] = Router::RouteMap.parsed_route[:path]					
			end
		end
	end

	def self.set &block
		RouteMap.new()
		root = lambda {|route| Router::Create.root(route) }
		resource = lambda {|route| Router::Create.resource(route) }
		static = lambda {|route| Router::Create.static(route) }
		block.call(root, resource, static)
	end

	def self.initialize! env_path, env_req_method
		require File.join(RFRAMEWORK_APP, "app", "config", "routes")
		Router::Create.routify(env_path, env_req_method)
	end

	def self.mix_and_match
		case Router::RouteMap.parsed_route[:request_method]
		when "GET"
			Router.find(Router::RouteMap.routes_via_get)
		when "POST"
			Router.find(Router::RouteMap.routes_via_post)
		when "DESTROY"
			Router.find(Router::RouteMap.routes_via_destroy)
		when "UPDATE"
			Router.find(Router::RouteMap.routes_via_update)
		end
	end

end