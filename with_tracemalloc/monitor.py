import tracemalloc
 
snaps = []
 
def snapshot(name="default"):
	snaps.append((name,tracemalloc.take_snapshot()))
 
 
def find_snap(name):
	if name : 
		for key, value in snaps:
			if key == name:
				return value
	else : 
		return snaps[-1][1]

def display_stats(name=None,key="filename"):
	stats = find_snap(name).statistics(key)
	print(f"\n*** top 5 stats grouped by {key} ***")
	for s in stats[:5]:
    	    print(s)
 
 
def compare(compare=None,to_=None):
	if compare and to_ :
		first = find_snap(compare)
		stats = find_snap(to_).compare_to(first, 'lineno')
		print("\n*** top 10 stats ***")
		for s in stats[:10]:
			print(f"**** {to_} compared to {compare}")
			print(s)
	elif compare :
		first = find_snap(compare)
		for key, value in snaps[1:]:
			stats = value.compare_to(first, 'lineno')
			print("\n*** top 10 stats ***")
			for s in stats[:10]:
				print(f"**** {key} compared to {compare}")
				print(s)
	else : 
		_ , first = snaps[0]
		_ , last = snaps[-1]
		stats = last.compare_to(first, 'lineno')
		print("\n*** top 10 stats ***")
		for s in stats[:10]:
			print(f"**** last snapshot compared to first snapshot.")
			print(s)
		
 
def print_trace(name=None):
	snapshot = find_snap(name).filter_traces((
    	    tracemalloc.Filter(False, "<frozen importlib._bootstrap>"),
    	    tracemalloc.Filter(False, "<frozen importlib._bootstrap_external>"),
    	    tracemalloc.Filter(False, "<unknown>"),
	))
	largest = snapshot.statistics("traceback")[0]
 
	print(f"\n*** Trace for largest memory block - ({largest.count} blocks, {largest.size/1024} Kb) ***")
	for l in largest.traceback.format():
    	    print(l)

