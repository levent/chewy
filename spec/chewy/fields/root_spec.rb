require 'spec_helper'

describe Chewy::Fields::Root do
  specify { expect(described_class.new('name').value).to be_a(Proc) }
  # TODO: add 'should_behave_like base_field'

  subject(:field) { described_class.new('product') }

  describe '#dynamic_template' do
    specify do
      field.dynamic_template 'hello', type: 'string'
      field.dynamic_template 'hello*', :integer
      field.dynamic_template 'hello.*'
      field.dynamic_template(/hello/)
      field.dynamic_template(/hello.*/)
      field.dynamic_template template_42: { mapping: {}, match: '' }
      field.dynamic_template(/hello\..*/)

      expect(field.mappings_hash).to eq(product: { dynamic_templates: [
        { template_1: { mapping: { type: 'string' }, match: 'hello' } },
        { template_2: { mapping: {}, match_mapping_type: 'integer', match: 'hello*' } },
        { template_3: { mapping: {}, path_match: 'hello.*' } },
        { template_4: { mapping: {}, match: 'hello', match_pattern: 'regexp' } },
        { template_5: { mapping: {}, match: 'hello.*', match_pattern: 'regexp' } },
        { template_42: { mapping: {}, match: '' } },
        { template_7: { mapping: {}, path_match: 'hello\..*', match_pattern: 'regexp' } }
      ] })
    end

    context do
      subject(:field) do
        described_class.new('product', dynamic_templates: [
          { template_42: { mapping: {}, match: '' } }
        ])
      end

      specify do
        field.dynamic_template 'hello', type: 'string'
        expect(field.mappings_hash).to eq(product: { dynamic_templates: [
          { template_42: { mapping: {}, match: '' } },
          { template_1: { mapping: { type: 'string' }, match: 'hello' } }
        ] })
      end
    end
  end
end
