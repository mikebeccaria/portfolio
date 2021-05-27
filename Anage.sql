/****** Exploring the AnAge Database of Animal Ageing and Longevity data set here https://genomics.senescence.info/species/index.html  ******/

--Find top 10 mammals with the longest lifespan
select top 10 class, common_name, maximum_longevity from anage_data
where class = 'Mammalia'
order by maximum_longevity desc
/*
class	common_name	maximum_longevity
Mammalia	Bowhead whale	211
Mammalia	Human	122.5
Mammalia	Fin whale	114
Mammalia	Blue whale	110
Mammalia	Humpback whale	95
Mammalia	Killer whale	90
Mammalia	Baird's beaked whale	84
Mammalia	Gray whale	77
Mammalia	Sperm whale	77
Mammalia	Sei whale	74
*/


--select top 5 species with longest lifespan grouped by kingdom
select class, common_name, maximum_longevity from
	(select *, r = row_number() over (partition by kingdom order by maximum_longevity desc) 
from anage_data) a
where r <= 5 and kingdom in (select distinct kingdom from anage_data)
/*
class	common_name	maximum_longevity
Hexactinellida	Hexactinellid sponge	15000
Demospongiae	Epibenthic sponge	1550
Bivalvia	Ocean quahog clam	507
Chondrichthyes	Greenland shark	392
Mammalia	Bowhead whale	211
Saccharomycetes	Baker's yeast	0.04
Schizosaccharomycetes	Fission yeast	NULL
Sordariomycetes	Filamentous fungus	NULL
Pinopsida	Great Basin bristlecone pine	5062
*/



--interesting - the data only showed 3 fungu and one plant - turns out the data has mostly animals. Let's try the same thing within the animal kingdom by phylum
--select top 5 species with longest lifespan grouped by kingdom
select kingdom, phylum, class, common_name, maximum_longevity from
	(select *, r = row_number() over (partition by phylum order by maximum_longevity desc) 
	from anage_data) a
where r <= 5 and kingdom = 'Animalia' and phylum in (select distinct phylum from anage_data)
order by kingdom,phylum,class,maximum_longevity desc
/*
kingdom	phylum	class	common_name	maximum_longevity
Animalia	Arthropoda	Insecta	Black garden ant	28
Animalia	Arthropoda	Insecta	Honey bee	8
Animalia	Arthropoda	Insecta	Cardiocondyla obscurior	0.5
Animalia	Arthropoda	Insecta	Squinting bush brown	0.5
Animalia	Arthropoda	Malacostraca	American lobster	100
Animalia	Chordata	Chondrichthyes	Greenland shark	392
Animalia	Chordata	Mammalia	Bowhead whale	211
Animalia	Chordata	Reptilia	Galapagos tortoise	177
Animalia	Chordata	Teleostei	Rougheye rockfish	205
Animalia	Chordata	Teleostei	Shortraker rockfish	157
Animalia	Cnidaria	Hydrozoa	Immortal jellyfish	NULL
Animalia	Echinodermata	Echinoidea	Red sea urchin	200
Animalia	Echinodermata	Echinoidea	Purple sea urchin	50
Animalia	Mollusca	Bivalvia	Ocean quahog clam	507
Animalia	Nematoda	Chromadorea	Roundworm	0.16
Animalia	Porifera	Demospongiae	Epibenthic sponge	1550
Animalia	Porifera	Hexactinellida	Hexactinellid sponge	15000
*/

--cool, the black garden ant can live 28 years!



--I wonder what the breakdown is by phylum - how many different phylums are there and what is their count?
select phylum, COUNT(*) as [count]
from anage_data
group by phylum
order by [count] desc
/*
phylum	count
Chordata	4200
Arthropoda	8
Ascomycota	3
Echinodermata	2
Porifera	2
Mollusca	1
Nematoda	1
Pinophyta	1
Cnidaria	1
*/
--wow, mostly chordata (4200 out of 4241 records)

--let's go down farther and look at class in the chordata phylum, going down to top 2
select kingdom, phylum, class, common_name, maximum_longevity from
	(select *, r = row_number() over (partition by class order by maximum_longevity desc) 
	from anage_data) a
where r <= 2 and kingdom = 'Animalia' and phylum = 'Chordata' and class in (select distinct class from anage_data)
order by kingdom,phylum,class,maximum_longevity desc
/*
kingdom	phylum	class	common_name	maximum_longevity
Animalia	Chordata	Amphibia	Olm	102
Animalia	Chordata	Amphibia	Japanese giant salamander	55
Animalia	Chordata	Aves	Pink cockatoo	83
Animalia	Chordata	Aves	Andean condor	79
Animalia	Chordata	Cephalaspidomorphi	European river lamprey	10
Animalia	Chordata	Cephalaspidomorphi	Pacific lamprey	9
Animalia	Chordata	Chondrichthyes	Greenland shark	392
Animalia	Chordata	Chondrichthyes	Spur dogfish	75
Animalia	Chordata	Chondrostei	Lake sturgeon	152
Animalia	Chordata	Chondrostei	Beluga sturgeon	118
Animalia	Chordata	Cladistei	Gray bichir	34
Animalia	Chordata	Coelacanthi	Coelacanth	48
Animalia	Chordata	Dipnoi	Australian lungfish	80
Animalia	Chordata	Dipnoi	African lungfish	18
Animalia	Chordata	Holostei	Longnose gar	36
Animalia	Chordata	Holostei	Bowfin	30
Animalia	Chordata	Mammalia	Bowhead whale	211
Animalia	Chordata	Mammalia	Human	122.5
Animalia	Chordata	Reptilia	Galapagos tortoise	177
Animalia	Chordata	Reptilia	Aldabra tortoise	152
Animalia	Chordata	Teleostei	Rougheye rockfish	205
Animalia	Chordata	Teleostei	Shortraker rockfish	157
*/
--humans make the cut now under mammalia but it seems reptiles and teleostei have really high longevity levels. Let's look at the averages for the top 5 maximum longevity numbers by class

select class, avg(maximum_longevity) as avglongevity from
	(select *, r = row_number() over (partition by class order by maximum_longevity desc) 
	from anage_data) a
	where r <= 5 and kingdom = 'Animalia' and phylum = 'Chordata' and class in (select distinct class from anage_data)
group by class
order by avglongevity desc
/*
class	avglongevity
Teleostei	153.8
Reptilia	142.8
Chondrichthyes	133.8
Mammalia	130.5
Chondrostei	114.8
Aves	74.2
Amphibia	55.6
Coelacanthi	48
Dipnoi	35.4333333333333
Cladistei	34
Holostei	26
Cephalaspidomorphi	8.8
*/
--looks like teleostei, and reptilia are the top
