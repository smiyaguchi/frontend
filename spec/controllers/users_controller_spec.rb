require 'spec_helper'

describe UsersController do
  login_user
  use_clojure_factories
  render_views
  let(:page) { Capybara::Node::Simple.new(@response.body) }


  it "should have a current_user" do
    subject.current_user.should_not be_nil
  end

  it "should render and have text" do
    get :dashboard
    response.body.should have_content("Latest build")
  end

  describe "dashboard" do
    before(:each) do
      @user = subject.current_user
      @projects = @user.projects
      @project = @projects[0]
    end

    it "should list all your projects" do
      get :dashboard
      response.body.should have_content("Status")

      @projects.each do |p|
        response.body.should have_link(p.github_project_name)
        link = page.find_link(p.github_project_name)
        link['href'].should == "/gh/" + p.github_project_name
      end
    end
  end
end
