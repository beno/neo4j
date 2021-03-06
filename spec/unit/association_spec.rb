require 'spec_helper'

class Default
end

describe Neo4j::ActiveNode::HasN::Association do
  let(:options) { {type: nil} }
  let(:name) { :default }
  let(:direction) { :out }

  let(:association) do
    Neo4j::ActiveNode::HasN::Association.new(type, direction, name, options)
  end
  subject do
    association
  end

  context 'type = :invalid' do
    let(:type) { :invalid }

    it { expect { subject }.to raise_error(ArgumentError) }
  end

  context 'has_many' do
    let(:type) { :has_many }

    ### Validations

    context 'direction = :invalid' do
      let(:direction) { :invalid }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'origin and type specified' do
      let(:options) { {type: :bar, origin: :foo} }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'type and rel_class specified' do
      let(:options) { {type: :foo, origin: :bar} }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'origin and rel_class specified' do
      let(:options) { {origin: :foo, rel_class: :bar} }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    describe '#arrow_cypher' do
      let(:var) { nil }
      let(:properties) { {} }
      let(:create) { false }

      subject { association.arrow_cypher(var, properties, create) }
      before do
        class MyRel
          def self._type
            'ar_type'
          end
        end
      end


      it { should == '-[]->' }

      context 'inbound' do
        let(:direction) { :in }

        it { should == '<-[]-' }
      end

      context 'bidirectional' do
        let(:direction) { :both }

        it { should == '-[]-' }
      end

      context 'creation' do
        let(:create) { true }

        it { should == '-[:`DEFAULT`]->' }

        context 'properties given' do
          let(:properties) { {foo: 1, bar: 'test'} }

          it { should == '-[:`DEFAULT` {foo: 1, bar: "test"}]->' }
        end
      end

      context 'varable given' do
        let(:var) { :fooy }

        it { should == '-[fooy]->' }

        context 'properties given' do
          let(:properties) { {foo: 1, bar: 'test'} }

          it { should == '-[fooy {foo: 1, bar: "test"}]->' }
        end

        context 'relationship type given' do
          let(:options) { {type: :new_type} }

          it { should == '-[fooy:`new_type`]->' }
        end

        context 'rel_class given' do
          let(:options) { {rel_class: MyRel} }

          it { should == '-[fooy:`ar_type`]->' }
        end

        context 'creation' do
          let(:create) { true }

          it { should == '-[fooy:`DEFAULT`]->' }

          context 'properties given' do
            let(:properties) { {foo: 1, bar: 'test'} }

            it { should == '-[fooy:`DEFAULT` {foo: 1, bar: "test"}]->' }
          end
        end
      end
    end

    describe '#target_class_names' do
      subject { association.target_class_names }

      context 'assumed model class' do
        let(:name) { :burzs }

        it { should == ['::Burz'] }
      end


      context 'specified model class' do
        context 'specified as string' do
          let(:options) { {type: :foo, model_class: 'Bizzl'} }

          it { should == ['::Bizzl'] }
        end

        context 'specified as class' do
          before(:each) do
            stub_const 'Fizzl', Class.new { include Neo4j::ActiveNode }
          end

          let(:options) { {type: :foo, model_class: 'Fizzl'} }

          it { should == ['::Fizzl'] }
        end
      end

      context 'with specified rel_class' do
        before(:each) do
          stub_const('TheRel',
                     Class.new do
                       def self.name
                         'TheRel'
                       end
                       include Neo4j::ActiveRel
                       from_class :any
                     end)
        end

        let(:options) { {rel_class: 'TheRel'} }

        context 'targeting any class' do
          before(:each) do
            TheRel.to_class(:any)
          end

          it { should be_nil }
        end

        context 'targeting a specific class' do
          context 'outbound' do
            before(:each) do
              stub_const 'Fizzl', Class.new { include Neo4j::ActiveNode }
              TheRel.to_class(Fizzl)
            end

            it { should == ['::Fizzl'] }
          end

          context 'inbound' do
            let(:direction) { :in }

            before(:each) do
              stub_const 'Buzz', Class.new { include Neo4j::ActiveNode }
              TheRel.from_class(Buzz)
            end

            it { should == ['::Buzz'] }
          end
        end
      end
    end

    describe 'target_class' do
      # subject { association.target_class }

      context 'with invalid target class name' do
        it 'raises an error' do
          expect(association).to receive(:target_class_names).at_least(1).times.and_return(['BadObject'])
          expect { association.target_class }.to raise_error ArgumentError
        end
      end
    end

    describe 'origin_type' do
      let(:start) {  Neo4j::ActiveNode::HasN::Association.new(:has_many, :in, 'name') }
      let(:myclass) { double('another activenode class') }
      let(:myassoc) { double('an association object') }
      let(:assoc_details) { double('the result of calling :associations', relationship_type: 'MyRel') }
      it 'examines the specified association to determine type' do
        expect(start).to receive(:target_class).and_return(myclass)
        expect(myclass).to receive(:associations).and_return(myassoc)
        expect(myassoc).to receive(:[]).and_return(assoc_details)
        expect(start.send(:origin_type)).to eq 'MyRel'
      end
    end

    describe 'relationship_class' do
      it 'returns the value of @relationship_class' do
        association.instance_variable_set(:@relationship_class, :foo)
        expect(association.send(:relationship_class)).to eq :foo
      end
    end

    describe 'unique' do
      context 'true' do
        let(:options) { {type: :foo, unique: true} }

        it do
          expect(subject).to be_unique
        end
      end

      context 'false' do
        let(:type) { :has_many }
        let(:options) { {type: :foo, unique: false} }

        it { expect(subject).not_to be_unique }
      end
    end
  end
end
