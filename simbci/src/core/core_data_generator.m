
classdef core_data_generator
% CLASS_DATA_GENERATOR Generates simulated EEG data
%
% USAGE:
%
% dataset = core_data_generator('key1',value1,'key2',value2, ... ).generate_dataset();
%

	properties
		usedParams
	end

	methods

	function obj = core_data_generator(varargin)
	% Default constructor
	%
	% varargin:
	%
	% 'timelineParams',{} - arguments to core_timeline
	% 'headParams',{},    - arguments to core_head
	% 'effectParams',{}   - arguments to generate_components() member function
	%
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		% Should correspond to a default timeline ...
		defaultEffects = { {'SNR', 1.0, 'name', 'freq1', 'triggeredBy', 'class1', ...
							'what', @noise_frequency_spike, 'whatParams', {'frequencyHz',1}, ...
							'where', @where_heuristic, 'whereParams', {'position','surface'}}, ...
							{'SNR', 1.0, 'name', 'freq2', 'triggeredBy', 'class2', ...
							'what', @noise_frequency_spike, 'whatParams', {'frequencyHz',2}, ...
							'where', @where_heuristic, 'whereParams', {'position','surface'}} ...							
							{'SNR', 2.0, 'name', 'noise', 'triggeredBy', 'always', ...
							'what', @noise_gaussian, ...
							'where', @where_heuristic, 'whereParams', {'position','surface'}}	
							};
		
		% @FIXME inefficiency below, default head is contructed to get the default params.
		addParameter(p,'id',                'anon',@ischar);
		addParameter(p,'headParams',        core_head().get_params(),        @iscell);
		addParameter(p,'timelineParams',    core_timeline().get_params(),    @iscell);		
		addParameter(p,'effectParams',      defaultEffects,    @iscell);
		addParameter(p,'keepVolumeData',    false, @islogical);
		addParameter(p,'visualize',         false, @islogical);

		p.parse(varargin{:});

		obj.usedParams = p.Results;
	end

	function dataset = generate_dataset( obj )
	% GENERATE_DATASET Generate EEG dataset
	%
	% Creates a timeline of BCI events of interest and samples the signal,
	% noise & artifacts. These are linearly mixed according to provided
	% SNR values for each component.
	%
	% Returns a dataset containing surface EEG data, an event timeline and
	% sample/trial labels.
	%

	%
	% See also core_timeline core_head
	%

		params = obj.usedParams;

		%%%%

		% Load the head model used in generation
		generatingHead = core_head(params.headParams{:});

		% Generate a timeline
		timeline = core_timeline(params.timelineParams{:});
		timeline = timeline.generate();

		% Generate and mix different components of the measured signal
		dataset = core_data_generator().generate_components(generatingHead, timeline, params.visualize, ...
					params.effectParams, obj.usedParams.keepVolumeData );

		% S may be no longer needed, cleaning up S can save a lot of memory
		if(~params.keepVolumeData)
			dataset.S = {};
		end

		dataset.id = params.id;
		dataset.generatingCall = obj.get_params();
		dataset.generatingVersion = platform_version();
		dataset.generatingDate = datestr(now(),30);

		if(params.visualize)
			figure();
			timeline.visualize();
			title(sprintf('%s - Final timeline', dataset.id));

			figure();
			imagesc(dataset.X);
			title(sprintf('%s - Final generated data', dataset.id));
			xlabel('Electrode');ylabel('Time');
			drawnow;
		end

	end

	function paramList = get_params(obj)
	% Returns the used parameters.
	%
	% defaultParams = core_data_generator().get_params();
	%
		paramList = struct_to_list(obj.usedParams);
	end


	% // methods
	end

	methods(Static,Access = private)

	function dataset = generate_components(generatingHead, timeline, visualize, componentList, keepVolumeData)
	% Linearly sums generated signal components provided in a list
	%
	% n.b. This will always return surface data. If volume noise is requested, it
	% is created in the volume and projected to the surface.
	%

		assert(~isempty(timeline) && ~isempty(timeline.event), 'Needs a timeline as input');

		dataset=timeline.get_empty_dataset();
		
		if(isfield(dataset,'X'))
			X = dataset.X;
		else
			X = zeros(dataset.numSamples,size(generatingHead.A,1));
		end

		dataset.S = {};

		usedParams=cell(1,length(componentList));
		for i=1:length(componentList)

			currentParam = componentList{i};

			p = inputParser;
			p.KeepUnmatched = false;
			p.CaseSensitive = true;
			p.PartialMatching = false;

			addParameter(p, 'name',                        'anon'         , @ischar);
			addParameter(p, 'triggeredBy',                 'always',        @ischar);
			addParameter(p, 'what',                        @noise_pink    , @isfunlist);
			addParameter(p, 'where',                       @where_heuristic,@isfunlist);
			addParameter(p, 'SNR',                         1.0,             @isnumeric);
			addParameter(p, 'allDirectionsCloned',         false,           @islogical);
			addParameter(p, 'smearStrength',               0,               @isnumeric);	 % should volume activity spread to neighbours

			p.parse(currentParam{:});
			params = p.Results;

			%%%%%

			if(params.SNR<=0)
				% Don't bother to compute
				continue;
			end

			assert(~isempty(params.triggeredBy),'Trigger not specified for component. If you wish to disable a component, set its SNR to 0');
						
			[whatFun,whatParams] = split_funlist(params.what);	
			[whereFun,whereParams] = split_funlist(params.where);

			% Where should this component originate from?
			[insertIntoIdxs,layer] = whereFun(generatingHead, whereParams{:});

			sizeof = [dataset.numSamples length(insertIntoIdxs)]; % may override howMany

			% Get a mask stating when this event is active
			mask = timeline.get_mask(params.triggeredBy);
			
			% Generate the component activity
			[generatedComp,details,subParams] = whatFun( sizeof, 'mask', mask, ...
				'dataset', dataset, 'physicalModel', generatingHead, whatParams{:} );
			assert(~isempty(generatedComp));

			usedParams{i}.params = params;
			usedParams{i}.subParams = subParams;
			usedParams{i}.details = details;

			% enable for debug...
			if(false && any(isnan(generatedComp(:))))
				fprintf(1,'Warning: Generator nr. %d produced NaNs, setting NaNs to 0\n',i);
				generatedComp(isnan(generatedComp)) = 0;
			end

			% If the data has a volumetric origin, put it there
			if(layer==1)
				S = core_data_generator.insert_into_volume(insertIntoIdxs, generatedComp, dataset, generatingHead, params);

				if(params.smearStrength>0)
					S = smear_activity(S, insertIntoIdxs, generatingHead, params.smearStrength);
				end
				if(visualize)
					core_data_generator.visualize_volume(S, i, length(componentList), insertIntoIdxs, dataset, generatingHead, details, params.name);
				end

				generatedComp = generatingHead.forward_transform(S);

				if(keepVolumeData)
					% warning: this potentially takes a lot of memory...
					dataset.S{i} = S;
				end
				clear S; % save memory
			else
				% its a surface component and fills whole surface, we can return it as is
				if(visualize)
					figure(); imagesc(generatedComp);
					title(sprintf('Comp %d/%d, surface: ''%s'' ', i, length(componentList), params.name));
					xlabel('Electrode');ylabel('Time');
					drawnow;
				end
			end

			% Scale the component to have the desired power
			% n.b. here we assume signals are more or less zero mean
			componentStd = std(generatedComp(:));
			if(componentStd>0)
				generatedComp = generatedComp .* ( sqrt( 1./params.SNR ) ./ componentStd );
			end

			% the following should be approx [0,1/SNR]
			% [mean(generatedComp(:)) var(generatedComp(:))]

			% Add the component to the data. This mixing is always on the surface
			% [ and possible due to the linearity assumption of the generative model,
			% for example A(s1 + s2) + x3 = A*s1 + A*s2 + x3 = x1 + x2 + x3. ]
			X = X + generatedComp;

			if(0)
				figure(1);
				subplot(length(componentList),2,2*i-1);imagesc(generatedComp);title('Comp');
				fprintf(1,'Comp %d added with var %f\n', i, var(generatedComp(:)));
				subplot(length(componentList),2,2*i);imagesc(X);title('Result');
				drawnow;
			end

			% Merge timelines if the generator made any new events
			if(isfield(details, 'events'))
				timeline = timeline.merge_events(details.events);
			end

			clear generatedComp;
		end

		dataset.componentParams = usedParams;
		dataset.electrodePos = generatingHead.electrodePos;   % Can be assumed to be known; useful for exporting
		dataset.events = timeline.get_events();
		dataset.X = X;

	end

	function S = insert_into_volume(sources, component, dataset, physicalModel, params)
	% Inserts the source activity in 'component'` to the empty volumetric
	% signal S in positions specified by 'sources'.

		S = zeros(size(component,1), size(physicalModel.A,2));
		if(physicalModel.constrainedOrientation || size(component, 2) == length(sources) )
			S(:,sources) = component;
		else
			% In this case we need to choose how each multidirectional source should be active.
			if(params.allDirectionsCloned)
				% If volume has 3dof/dipole, we'll duplicate each 1 dim -> 3 dim.
				v = repmat(1:size(S,2),[3 1]); v = v(:);
				S(:,sources) = S(:,v);
			else
				% Alternatively, we use 3 independently active directions and assign them
				comp2 = params.generator( size(component), 'dataset', dataset, 'physicalModel', physicalModel, params.genParams{:} );
				comp3 = params.generator( size(component), 'dataset', dataset, 'physicalModel', physicalModel, params.genParams{:} );
				S(:,sources(1:3:end)) = component;
				S(:,sources(2:3:end)) = comp2;
				S(:,sources(3:3:end)) = comp3;
			end
		end
	end

	function visualize_volume(S, index, total, sources, dataset, generatingHead, details, name)
	% Show the volumetric source locations along with the sources themselves and the timeline

		plotAsImage = false;
		if(length(sources)>6)
			fprintf(1,'Warning: Too many sources to plot nicely, plotting as image\n');
			plotAsImage = true;
		end

		if(~plotAsImage)
			% figure();
			yMin = min(S(:));
			yMax = max(S(:));
			if(isfield(details,'events') && ~isempty(details.events))
				numPlots = length(sources)+1;
				hasEvents = true;
			else
				numPlots = length(sources);
				hasEvents = false;
			end

			figure();
			subplot(numPlots,2,1:2:2*numPlots);
			generatingHead.visualize(sources); title(sprintf('Comp %d/%d, volume: ''%s'' sources', index, total, name));

			for i=1:length(sources)
				src = sources(i);
				subplot(numPlots,2,2*i);
				plot((0:size(S,1)-1)/dataset.samplingFreq, S(:,src)); title(sprintf('Volume src %d', i));
				if(yMin~=0 && yMax~=0)
					ylim([yMin yMax]);
				end
				xlabel('Time');ylabel('Amplitude');
			end
			if(hasEvents)
				subplot(numPlots, 2, 2*numPlots);
				core_timeline().construct_from_events(details.events).visualize();
				drawnow;
			end
		else
			tmp = S;
			if(isfield(details,'events'))
				m = max(tmp(:));
				tmp = repmat(tmp,[1 1 3]);
				for i=1:length(details.events)
					tmp(details.events.latency,:,1) = m;
				end
			end
			subplot(1,2,1);
			generatingHead.visualize(sources); title(sprintf('Comp %d/%d, volume: ''%s'' sources', index, total, name));
			subplot(1,2,2);
			imagesc(tmp);
			drawnow;
		end
		
	end

	% // Methods(Static, Access = private)
	end

% // Class
end
