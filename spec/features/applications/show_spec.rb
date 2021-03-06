require 'rails_helper'

RSpec.describe 'As a visitor' do
  describe 'when I visit an applications show page' do
    before :each do
      @shelter = Shelter.create!(
        name: 'FurBabies4Ever',
        address: '1664 Poplar St',
        city: 'Denver',
        state: 'CO',
        zip: '80220'
      )
      @pet_1 = @shelter.pets.create!(
        name: 'Rufus',
        sex: 'male',
        age: '3',
        image: 'https://www.washingtonpost.com/resizer/uwlkeOwC_3JqSUXeH8ZP81cHx3I=/arc-anglerfish-washpost-prod-washpost/public/HB4AT3D3IMI6TMPTWIZ74WAR54.jpg',
        description: 'The cutest dog in the world. Adopt him now!'
      )
      @application = Application.create!(
        name: 'Phil',
        address: '55 whatever st',
        city: 'Denver',
        state: 'CO',
        zip: '33333',
        phone_number: '3434343434',
        description: 'some text'
      )
      @application_2 = Application.create!(
        name: 'Ryan',
        address: '33 different st',
        city: 'Denver',
        state: 'CO',
        zip: '33333',
        phone_number: '3434343434',
        description: 'some text'
      )
      @pet_application = PetApplication.create!(application: @application, pet: @pet_1)
      @pet_application_2 = PetApplication.create!(application: @application_2, pet: @pet_1)
    end

    it 'I can see the application name, address, city, state, zip, phone number, and description' do
      visit "/applications/#{@application.id}"

      expect(page).to have_content('Name: Phil')
      expect(page).to have_content('Address: 55 whatever st')
      expect(page).to have_content('City: Denver')
      expect(page).to have_content('State: CO')
      expect(page).to have_content('Zip: 33333')
      expect(page).to have_content('Phone Number: 3434343434')
      expect(page).to have_content('Description: some text')
    end

    it "I can see names (links to pet show) of all the pet's this application is for" do
      visit "/applications/#{@application.id}"

      expect(page).to have_link('Rufus')
      click_link 'Rufus'
      expect(current_path).to eq("/pets/#{@pet_1.id}")
    end

    describe 'for every pet that the application is for' do
      it 'I see a link to approve the application for that specific pet' do
        visit "/applications/#{@application.id}"

        within '.pets-on-application' do
          expect(page).to have_link('Approve Application')
        end
      end

      describe 'when I click on a link to approve the application for one particular pet' do
        it "I'm taken back to that pet's show page" do
          visit "/applications/#{@application.id}"

          click_link 'Approve Application'

          expect(current_path).to eq("/pets/#{@pet_1.id}")
        end

        it "I see that the pets status has changed to 'pending'" do
          visit "/applications/#{@application.id}"

          click_link 'Approve Application'

          expect(page).to have_content("Adoptable Status: pending")
        end

        describe "When the pet already has an approved application" do
          describe "And I try to approve another application" do
            it "I see a flash message that no more applications can be approved" do
              visit "/applications/#{@application.id}"
              click_link 'Approve Application'

              visit "/applications/#{@application_2.id}"

              expect(page).to_not have_link('Approve Application')
            end
          end
        end
      end
    end

    describe 'when an application is made for more than one pet' do
      it "I'm able to approve the application for any number of pets" do
        pet_2 = @shelter.pets.create!(
          name: 'Snuggles',
          sex: 'female',
          age: '5',
          image: 'https://upload.wikimedia.org/wikipedia/commons/6/66/An_up-close_picture_of_a_curious_male_domestic_shorthair_tabby_cat.jpg',
          description: 'A lovable orange cat. Adopt her now!'
        )
        pet_application_2 = PetApplication.create!(application: @application, pet: pet_2)

        visit "/applications/#{@application.id}"

        all(:link, 'Approve Application')[0].click

        expect(page).to have_content("Adoptable Status: pending")

        visit "/applications/#{@application.id}"

        all(:link, 'Approve Application').last.click

        expect(page).to have_content("Adoptable Status: pending")
      end
    end

    describe 'after an application has been approved for a pet' do
      it 'I no longer see a link to approve the application for that pet' do
        visit "/applications/#{@application.id}"

        click_link 'Approve Application'

        visit "/applications/#{@application.id}"

        expect(page).to_not have_link('Approve Application')
      end

      it 'I see a link to revoke the application for that pet' do
        visit "/applications/#{@application.id}"

        click_link 'Approve Application'

        visit "/applications/#{@application.id}"

        expect(page).to have_link('Revoke Application')
      end

      describe 'when I click on the link to unapprove the application' do
        it "I'm taken back to that applications show page" do
          visit "/applications/#{@application.id}"

          click_link 'Approve Application'

          visit "/applications/#{@application.id}"

          click_link 'Revoke Application'

          expect(current_path).to eq("/applications/#{@application.id}")
        end

        it 'I can see the button to approve the application for that pet again' do
          visit "/applications/#{@application.id}"

          click_link 'Approve Application'

          visit "/applications/#{@application.id}"

          click_link 'Revoke Application'

          expect(page).to have_link('Approve Application')
        end

        describe 'when I go to that pets show page' do
          it 'I can see that the pets adoption status is now back to adoptable' do
            visit "/applications/#{@application.id}"

            click_link 'Approve Application'

            visit "/applications/#{@application.id}"

            click_link 'Revoke Application'

            visit "/pets/#{@pet_1.id}"

            expect(page).to have_content("Adoptable Status: adoptable")
          end
        end

        describe "I see the applicant's name as a link" do
          it "When I click the link it takes me to the application show page" do
            visit "/applications/#{@application.id}"

            expect(page).to have_link('Phil')
            click_link 'Phil'
            expect(current_path).to eq("/applications/#{@application.id}")
          end
        end
      end
    end
  end
end
