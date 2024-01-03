# frozen_string_literal: true

module MetricJobs
  class CalculateSubjects < ApplicationJob
    queue_as :low

    def perform
      metric_classes.each do |metric_class|
        metric_class.subject_model.all.find_each do |record|
          MetricJobs::CalculateSingle.perform_later(metric_class, record)
        end
      end
    end

    private

    def metric_classes
      Metric.descendants.select do |c|
        c.included_modules.include?(Metric::Subject)
      end
    end

  end
end
