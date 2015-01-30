---
title: If Business Logic worked like a business
date: 2015-01-30 13:55 UTC
tags: Ruby, Patterns
---
It often seems as if half the battle with building and maintaining large web applications 
is determining where the logic should go. 
  
We start off by making our controllers 'skinny'. 
This is almost a given, and makes sense when you consider them as simple 'adapters' in a 
[hexagonal architecture](http://victorsavkin.com/post/42542190528/hexagonal-architecture-for-rails-developers).
All the controller needs to do is make sure it can serve the request, 
and act as a mediator between the application and the user.

P.S. If you really want to see what hell fat controllers can cause, try doing some heavy customisation on Magento. 
You'll soon develop a really good feel for why they shouldn't be telling the others how to do their job.
 
So now we come across issues where our models are taking on a bit too much, 
and aren't quite as agile as they used to be.
There is endless debate about how to deal with fat models, **and for good reason**. 
It is not something that can be dealt with by one single 'rule' or 'strategy' acting as a panacea.
 
To understand the complexity, perhaps we draw a metaphor as the application as a business,
and look at how business logic is applied. 
When you consider the metaphor, there are a staggering number of similarities in how business logic affects 
complexity and agility.

## It all about Separation of Concerns

For a business to work well, we can't have silos, 
but each person in the business needs to know what their role is, and do that role well. 
Consider that you shouldn't have to tell your co-worker how to do their job, 
but you definitely need to know what she is doing if it affects your work. 

There's always a balance needed, and it is very rarely met just right in practice.
There is not a single organisational structure that suits all businesses.
In fact, for most large businesses, I would not expect a single arrangement to suit every working group within it. 

So we need a pick and mix of strategies, each with their own characteristics. 

## The callback

This could be considered quite an informal arrangement that gets things done without much red tape. 
Bob has a note on his desk saying "Before you file the quote, make sure you get Sally to add the taxes". 

This is nice and simple, but fill Bob's desk with twenty more notes and he might start complaining that he has his 
fingers in too many pies, and would rather concentrate on his own work. 
What happens when management forgets to tell Bob that Sally no longer works there, or that she's struggling with
her workload so there is a receptionist to deal with her jobs. Bob will keep doing the wrong thing. 

Sure, tell Bob if you remember, 

As the business grows, the callback becomes a bit of a liability.
 
Bob find's a P.S. at the bottom of the note. 
"It's probably best you give Sally the quote, and politely request that she write the full details down on it, 
we don't want a repeat of last time you just asked her for the figures and accidentally mixed up VAT with GST"

## The listening committee

Bob got so frustrated, he asked for something to be done. 
The director decided to set up a group of people who just 
sit around all day waiting for people to tell them when they've reached a certain point in the tasks. 
One or more of these people might be interested that Bob is about to finish a quote, 
and organise for someone else do do something with it. 
 
This came with a problem, and it wasn't that they were demanding too much money for doing nothing.
Oh no, these workers are paid by the millisecond.
 
The problems were noticed by the director. 
He had a call to say that a client never received a quote that was supposed to be emailed to them.
 
When the director approached Bob to find out what was going on, all he could say was 
"Meh, I created the quote, didn't I"

The communications department reported that they never received a request to send a quote. 

Something's just not right, and the director has no visibilty over it. 
She naturally assumes the best solution to the problem is to make sure bob tells the communications department.

A week later, there are reports of people getting multiple quote emails. What the hell is going on? 
She remembers that pesky listening committee! 

She asks all of them whether they have anything to do with quotes and emails.
One of them replies, "Oh yeah, I didn't think the communications department needed to worry about that quote."

So while the ever-opinionated Rails deprecated Observers in 4.0, 
Magento has been using them extensively and to great effect to allow customisation.
    
What is the difference? Well probably close to 8 million lines of code, and the fact that Magento is a big corporation.
Magento is also a complete platform rather than a framework.
Magento can't really deal with having each department even know about the other
if the director needs to swap out one of the departments.  
In fact, the Magento 'director' is so used to dealing with with the corporation as it is 
that he considers the departments to be more like agencies that the company employs, and he is constantly consulting
his listening committee as he knows they often have their hand in things 
to make sure each agency's output is what they need.

The director take a while to reflect then tells the listening committee 
"It's not your job to make business decisions!"

## Service objects

Well then, whose job is it to make those decisions? There are just too many for one person to handle, 
but the director needs to have visibility over the entire business if needed.
 
What we need is middle management!

Let's create a Manager whose job is to ensure customer's get their invoices. What a novel idea!

Steve is hired for the job, and we just need to make sure that Estelle knows to tell him whenever 
a customer might need an invoice. 
Steve isn't going anywhere in a hurry, and if he needs to change the process, he will handle it, end to end.

Bob just does what he's told, and doesn't care too much about what is outside his control. 

The problem? Well it mostly works. We just need to hire smart Managers who know how and when to delegate.
Not too much, not too little. 
Oh, and sometimes the staff get a little bit confused when multiple people are telling them what to do. 

Oh, and we don't want too many managers on a single level, they tend to confuse things and start conflicts.

Want managers who do their job well, and know their place? 
[Try making their job descriptions as clear as possible.](http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html)

## Get me the business consulting group on the line!

I wonder if the metaphor could be taken a lot further, or is already stretched too far, 
or whether it is even a good way to look at an application.

We didn't even get into SOLID principles 
and the details on how the staff need to communicate or what their job descriptions should be.

The point of the whole exercise is to illustrate a large application, like a business, is not at all simple.
For each, there is no perfect recipe that always works (other than having all the experience in the world). 

Simplicity is a good thing that we should always strive for, but realise that it is not going to come out of one thing.

