require 'time'
require 'sinatra'
require 'mysql2'
require 'yaml'
require 'haml'

module Sinatra

  class SinatraApp < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions
    enable :inline_templates

    set :mysql do
      host = ENV['DB_HOST'] || 'localhost'
      database = ENV['DB_NAME'] || 'mysql'
      username = ENV['DB_USER'] || 'mysql'
      password = ENV['DB_PASSWORD'] || 'mysql'
      Mysql2::Client.new host: host, database: database, username: username,
          password: password
    end

    get '/' do
      # list of employees that are Male which birth date is 1965-02-01 and
      # the hire date is greater than 1990-01-01 ordered by
      # the Full Name of the employee
      #  Field      | Type          | Null | Key | Default | Extra
      # ------------+---------------+------+-----+---------+-------
      #  emp_no     | int(11)       | NO   | PRI | NULL    |
      #  birth_date | date          | NO   |     | NULL    |
      #  first_name | varchar(14)   | NO   |     | NULL    |
      #  last_name  | varchar(16)   | NO   |     | NULL    |
      #  gender     | enum('M','F') | NO   |     | NULL    |
      #  hire_date  | date          | NO   |     | NULL    |
      statement = settings.mysql.prepare "SELECT emp_no, first_name, " \
          "last_name, birth_date, hire_date, gender FROM employees WHERE " \
          "DATE(birth_date) = ? AND DATE(hire_date) > ? AND gender = ? " \
          "ORDER BY first_name, last_name"
      @result = statement.execute('1965-02-01', '1990-01-01', 'M')
      haml :index
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run SinatraApp
    end
  end
end

run Sinatra.app

__END__

@@ layout
!!!
%html{:lang => "en"}
  %head
    %meta{:content => "text/html; charset=UTF-8", "http-equiv" => "Content-Type"}/
    %title
      List of employees
    %meta{:charset => "utf-8"}/
    %meta{:content => "width=device-width, initial-scale=1", :name => "viewport"}/
    %link{:href => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css", :rel => "stylesheet"}/
    %script{:src => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"}
  :css
    .glyphicon { margin-right: 4px; }
  %body
    = yield
    .navbar.navbar-inverse.navbar-fixed-bottom
      .navbar-inner
        .container.text-center
          %ul.nav.navbar-nav.navbar-right
            %li
              %p.navbar-text= Time.now.utc.iso8601

@@index
.jumbotron
  .container
    .table-responsive
      %table.table
        %h2
          List of employees that are Male which birth date is 1965-02-01 and
          the hire date is greater than 1990-01-01 ordered by
          the Full Name of the employee
        %tr
          %th ID
          %th Full Name
          %th Birth Date
          %th Hire Date
          %th Gender
        - @result.each do |item|
          %tr
            %td= item['emp_no']
            %td
              = item['first_name']
              = item['last_name']
            %td= item['birth_date']
            %td= item['hire_date']
            %td= item['gender']
