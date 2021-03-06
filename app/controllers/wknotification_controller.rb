# ERPmine - ERP for service industry
# Copyright (C) 2011-2020  Adhi software pvt ltd
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class WknotificationController < WkbaseController
  menu_item :wkcrmenumeration
  accept_api_auth :index, :updateUserNotification

  def index
    @notification = WkNotification.all.pluck(:name)
    @checkEmail = WkNotification.first.try(:email)
    @userNotification = WkUserNotification.where('user_id = ?', User.current.id).order(id: :desc)
		respond_to do |format|
			format.html {
			  render :layout => !request.xhr?
			}
			format.api
		end
  end

  def update
    errorMsg = nil
    actionName = []
    params['notify'].each{ |key, value| actionName << key.split('_').last }
    removeName = WkNotification.where.not(name: actionName)
    removeName.destroy_all
    params['notify'].each do |name, value|
      notifiedName = name.split('_')
      notification = WkNotification.where(modules: notifiedName.first, name: notifiedName.last).first_or_initialize(modules: notifiedName.first, name: notifiedName.last)
      notification.email = params['email'] || false
      if !notification.save()
				errorMsg += notification.errors.full_messages.join('\n')
			end
    end
    respond_to do |format|
      format.html {
        if errorMsg.nil?
          flash[:notice] = l(:notice_successful_update)
        else
          flash[:error] = errorMsg
        end
        redirect_to controller: 'wknotification', action: 'index' , tab: 'wknotification'
      }
    end
  end

  def updateUserNotification
		errorMsg = nil
    usrNotification = WkUserNotification.find(params[:id])
    if usrNotification.user_id == User.current.id
      usrNotification.seen = true
      usrNotification.seen_on = Time.now
      if usrNotification.valid?
        usrNotification.save()
      else
        errorMsg = usrNotification.errors.full_messages.join("<br>")
      end
    end
		render json: errorMsg
  end
end
