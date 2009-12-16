# Create your views here.

from django.http      import HttpResponse
from django.template  import Context, loader, RequestContext
from django.shortcuts import render_to_response
from urllib           import quote, unquote
from django.db.models import Count
from django.db        import connection
import mainsite.models as model
from mainsite.models  import Filing,Client,Registrant,Issue,Lobbyist

defaultTop = 20

def dictAdd(d, k,v):
    "Add one more key to a dict"
    d[k] = v
    return d

def make_key(s):
    """Need to make a "key" field to produce links with. We'll use code, url encoded with slashes turned to dashes"""
    return quote(s.replace('/','-').lower())

def unquote_key(s):
    """Need to make a "key" field to produce links with. We'll use code, url encoded with slashes turned to dashes"""
    return unquote(s).upper().replace('-','/')

def index(request):
    return render_to_response("index.html", locals(), context_instance = RequestContext(request))

def issues(request, top = defaultTop):
    #import pdb
    #pdb.set_trace()
    top_issues_raw = model.issue.get_top(top)
    top_issues = [dictAdd(issue,'key',make_key(issue['code']) )  for issue in top_issues_raw]
    issues_sum = sum(issue['count'] for issue in top_issues)
    return render_to_response("issue/top_issues.html", locals(), context_instance = RequestContext(request))

def issue_detail(request, code, top = defaultTop):
    #import pdb
    #pdb.set_trace()
    id = unquote_key(code)
    #issue = model.issue.get(id)
    filings = model.issue.get_with_filings(id, top)
    return render_to_response("issue/issue.html", locals(), context_instance = RequestContext(request))

def lobbyists(request, top = defaultTop):
    #import pdb
    #pdb.set_trace()
    #top_lobbyists = Lobbyist.objects.annotate(num_filings=Count('filings')).order_by('-num_filings')[:5] #
    cursor = connection.cursor()
    #Really needs an index on column lobbyist_id in join table mainsite_lobbyist_filings
    #TODO: always returns lobbyists with 1 filing, suspect something wrong with migration script
    cursor.execute("SELECT lobbyist_id, COUNT(lobbyist_id) FROM mainsite_lobbyist_filings GROUP BY lobbyist_id ORDER BY COUNT(lobbyist_id) DESC LIMIT %d" % top)
    ids =[x[0] for x in cursor.fetchall()]
    top_lobbyists = Lobbyist.objects.filter(pk__in = ids) #.annotate(count=Count('filing')) #Also slow
    top_lobbyists = sorted(top_lobbyists, key=lambda x: x.filings.count(), reverse=True) #Need to resort again
    return render_to_response("lobbyist/top_lobbyists.html", locals(), context_instance = RequestContext(request))

def lobbyist_detail(request, first_name, last_name):
    first_name = first_name.upper()
    last_name  = last_name.upper()
    #lobbyists = model.lobbyist.get(first_name,last_name) #Will get multiple rows
    filings = model.lobbyist.get_with_filings(first_name, last_name)
    return render_to_response("lobbyist/lobbyist.html", locals(), context_instance = RequestContext(request))

def clients(request, top = defaultTop):
    #This query is slow
    #clients = Client.objects.annotate(num_filings = Count('filing')).order_by('-num_filings')[:top]
    cursor = connection.cursor()
    cursor.execute("SELECT client_id, COUNT(client_id)  FROM mainsite_filing where client_id != 0 GROUP BY client_id  ORDER BY COUNT(client_id) DESC LIMIT %d" % top)
    ids =[x[0] for x in cursor.fetchall()]
    top_clients = Client.objects.filter(pk__in = ids) #.annotate(count=Count('filing')) #Also slow
    top_clients = sorted(clients, key=lambda x: x.filing_set.count(), reverse=True) #Need to resort again
    return render_to_response("client/top_clients.html", locals(), context_instance = RequestContext(request))

def client_detail(request,client_id):
    filings = model.client.find_by_id(client_id)
    filings_sum = sum(filing['filing_amount'] for filing in filings)
    return render_to_response("client/client.html", locals(), context_instance = RequestContext(request))

def registrants(request, top = defaultTop):
    #Slow query
    #top_registrants  = Registrant.objects.annotate(num_filings = Count('filing')).order_by('-num_filings')[:top]
    cursor = connection.cursor()
    cursor.execute("SELECT registrant_id, COUNT(registrant_id)  FROM mainsite_filing where registrant_id != 0 GROUP BY registrant_id  ORDER BY COUNT(registrant_id) DESC LIMIT %d" % top)
    ids =[x[0] for x in cursor.fetchall()]
    top_registrants = Registrant.objects.filter(pk__in = ids) #.annotate(count=Count('filing')) #Also slow
    top_registrants = sorted(top_registrants, key=lambda x: x.filing_set.count(), reverse=True) #Need to resort again
    return render_to_response("registrant/top_registrants.html", locals(), context_instance = RequestContext(request))

def registrant_detail(request, registrant_id, top = defaultTop):
    top_clients = model.registrant.top_clients(registrant_id, top)
    return render_to_response("registrant/registrant.html", locals(), context_instance = RequestContext(request))
