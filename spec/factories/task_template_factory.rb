FactoryBot.define do
  factory :task_template do
    sequence(:title) { |n| "Task template ##{n}" }

    user
    team { user.team }

    factory :with_tasks_and_subtasks do
      transient do
        tasks_count { 2 }     # Number of tasks to create
        subtasks_count { 2 }  # Number of subtasks per task
      end

      after(:create) do |task_template, evaluator|
        evaluator.tasks_count.times do
          task = create(:task, project: nil, team: task_template.team, template: true, task_template:)
          evaluator.subtasks_count.times do
            create(:task, project: nil, team: task_template.team, template: true, task_template:,
              parent: task)
          end
        end
      end
    end
  end
end
