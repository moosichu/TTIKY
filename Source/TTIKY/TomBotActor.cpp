// Fill out your copyright notice in the Description page of Project Settings.


#include "TomBotActor.h"

// Sets default values
ATomBotActor::ATomBotActor()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void ATomBotActor::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void ATomBotActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

