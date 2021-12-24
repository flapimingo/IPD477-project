

classdef proc_identity
	% Just a passthrough

	properties

	end

	methods

	function [ obj,feats ] = train(obj, trainData, varargin)

		feats = trainData.X;

	end

	function feats = process(~, data)

		feats = data.X;

	end

	end

end
