import pandas as pd

df = pd.read_fwf("build/monitor.log", colspecs=[(0,3), (3,7), (68,100)], names=['t','addr','cycle'], header=None)
df = df.query('t==".C:"').drop('t', axis='columns')
df.addr = df.addr.map(lambda x: int(x,16))
df['cycles'] = df.cycle.diff()
df = df.dropna().convert_dtypes()

cum = df.groupby('addr').cycles.sum()
hot = cum.sort_values().tail(50)

labels = pd.read_fwf('forth.lbl', header=None, names=['t', 'addr', 'name']).drop('t', axis='columns')
labels.addr = labels.addr.map(lambda x: int(x,16)).set_index('addr').sort_index()

where = pd.merge_asof(hot.sort_index(), labels, left_index=True, right_index=True)
where.groupby('name').sum().sort_values('cycles').tail(50)

