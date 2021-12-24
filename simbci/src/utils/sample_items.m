function samples = sample_items( items, probs, count )
% Samples 'count' entries from 'items' with replacement, given
% probabilities to pick each item

	assert(length(items)==length(probs));
	assert(all(probs>=0));

	probs = probs / sum(probs);
	split = min([0 cumsum(probs)],1);
	split(end)=1;
	split = repmat(split, [count, 1]);

	r = rand(count, 1);
	r = repmat(r, [1 size(split,2)]);

	weighted = (r>split) .* repmat(1:size(split,2),[count,1]);
	[~,idxs] = max(weighted, [],2);

	samples = items(idxs);

end


